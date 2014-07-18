/*
    testme.es -- MakeMe Unit Test
 */
module ejs.testme {

require ejs.unix

enumerable class TestMe {
    const TIMEOUT: Number = 5 * 60 * 1000

    var cfg: Path?                          //  Path to configuration outputs directory
    var bin: Path                           //  Path to bin directory
    var depth: Number = 1                   //  Test level. Higher levels mean deeper testing.
    var top: Path                           //  Path to top of source tree

    var keepGoing: Boolean = false          //  Continue on errors 
    var topEnv: Object = {}                 //  Global env to pass to tests
    var filters: Array = []                 //  Filter tests by pattern x.y.z... 
    var noserver: Boolean = false           //  Omit running a server (sets NOSERVER=1)
    var skipDirectory: Boolean              //  Skip current directory
    var options: Object                     //  Command line options
    var program: String                     //  Program name
    var log: Logger = App.log
    var start = Date.now()
    var startTest
    var verbosity: Number = 0

    var failedCount: Number = 0
    var passedCount: Number = 0
    var skippedCount: Number = 0
    var testCount: Number = 0

    function unknownArg(argv, i) {
        let arg = argv[i].slice(argv[i].startsWith("--") ? 2 : 1)
        if (arg == '?') {
            tm.usage()
        } else if (isNaN(parseInt(arg))) {
            throw 'Unknown option: ' + arg
        }
        return i+1
    }

    let argsTemplate = {
        options: {
            chdir: { range: Path },
            compile: {},
            clean: {},
            clobber: {},
            'continue': { alias: 's' },
            debug: { alias: 'd' },
            depth: { range: Number },
            log: { alias: 'l', range: String },
            noserver: { alias: 'n' },
            projects: { alias: 'p' },
            rebuild: { alias: 'r' },
            show: { alias: 's' },
            why: { alias: 'w' },
            verbose: { alias: 'v' },
            version: { },
        },
        unknown: unknownArg,
        usage: usage,
    }

    function usage(): Void {
        let program = Path(App.args[0]).basename
        App.log.write('Usage: ' + program + ' [options] [filter patterns...]\n' +
            '  --chdir dir           # Change to directory before testing\n' + 
            '  --clean               # Clean compiled tests\n' + 
            '  --clobber             # Remove testme directories\n' + 
            '  --compile             # Compile all C tests\n' + 
            '  --continue            # Continue on errors\n' + 
            '  --depth number        # Zero == basic, 1 == throrough, 2 extensive\n' + 
            '  --log file:level      # Log output to file at verbosity level\n' + 
            '  --noserver            # Do not run server side of tests\n' + 
            '  --projects            # Generate IDE projects for tests\n' + 
            '  --rebuild             # Rebuild all tests before running\n' + 
            '  --show                # Show commands executed\n' +
            '  --verbose             # Verbose mode\n' + 
            '  --version             # Output version information\n' +
            '  --why                 # Show why commands are executed\n')
        App.exit(1)
    }

    function parseArgs(): Void {
        let args = Args(argsTemplate, App.args)
        options = args.options
        filters += args.rest

        if (options.chdir) {
            App.chdir(options.chdir)
        }
        if (options['continue']) {
            keepGoing = true
        }
        if (options.depth) {
            depth = options.depth
            if (depth < 1 || depth > 9) {
                depth = 1
            }
        }
        if (options.noserver) {
            noserver = true
            topEnv.TM_NOSERVER = '1';
        }
        if (options.verbose) {
            verbosity++
        }
        if (options.projects) {
            if (filters.length == 0) {
                App.log.error('Must specify at least one test')
                App.exit(1)
            }
        }
        if (options.version || options.log) {
            /* Handled in C code */
        }
    }

    function TestMe() {
        program = Path(App.args[0]).basename
        if ((path = searchUp('configure')) != null) {
            top = path.dirname.absolute
            try {
                if (top.join('start.me')) {
                    cfg = top.join('build', Cmd.run('me --showPlatform', {dir: top}).trim())
                }
            } catch {}
            if (!cfg) {
                cfg = top.join('build').files(Config.OS + '-' + Config.CPU + '-*').sort()[0]
                if (!cfg) {
                    let hdr = top.files('build/*/inc/me.h').sort()[0]
                    if (hdr) {
                        cfg = hdr.trimEnd('/inc/me.h')
                    }
                }
            }
            if (cfg.join('inc/me.h').exists) {
                parseMeConfig(cfg.join('inc/me.h'))
            }
        }
    }

    function setupEnv() {
        blend(topEnv, {
            TM_TOP: top, 
            TM_CFG: cfg, 
            TM_DEPTH: depth, 
        })
    }

    /*
        Main test runner
     */
    function runAllTests(): Void {
        trace('Test', 'Starting tests. Test depth: ' + depth)
        setupEnv()
        runDirTests('.', topEnv)
    }

    function runDirTests(dir: Path, parentEnv): Boolean {
        skipDirectory = false
        let env = parentEnv.clone()
        for each (file in dir.files('*.set')) {
            if (!runTest('Setup', file, env)) {
                return false
            }
        }
        if (skipDirectory) {
            skipDirectory = false
            return true
        }
        try {
            if (!dir.exists) {
                log.error('Cannot read directory: ' + dir)
            }
            for each (file in dir.files('*.com')) {
                if (!runTest('Setup', file, env)) {
                    return false
                }
            }
            for each (file in dir.files('*')) {
                if (filters.length > 0) {
                    let found
                    for each (let filter: Path in filters) {
                        if (file.isDir && filter.startsWith(file)) {
                            found = true
                            break
                        }
                        if (file.startsWith(filter)) {
                            found = true
                            break
                        }
                    }
                    if (!found) {
                        continue
                    }
                }
                if (file.isDir) {
                    if (!runDirTests(file, env)) {
                        return false
                    }
                } else if (file.extension == 'tst') {
                    if (!runTest('Test', file, env)) {
                        return false
                    }
                }
                if (skipDirectory) {
                    skipDirectory = false
                    break
                }
            }
        } catch (e) {
            /* Exception in finally without this catch */
        }
        finally {
            for each (file in dir.files('*.set')) {
                runTest('Finalize', file, env)
            }
        }
        return true
    }

    function runTest(phase, file: Path, env): Boolean {
        if (!file.exists) {
            return true
        }
        blend(env, {
            TM_PHASE: phase,
            TM_DIR: file.dirname,
        })
        let home = App.dir
        let cont = true
        try {
            App.chdir(file.dirname)
            cont = runTestFile(phase, file, file.basename, env)
        } catch (e) {
            failedCount++
            throw e
        } finally {
            App.chdir(home)
        }
        return cont
    }

    /*
        Run a test file with changed directory. topPath is the file from the original home.
     */
    function runTestFile(phase, topPath: Path, file: Path, env): Boolean {
        vtrace('Testing', topPath)
        if (phase == 'Test') {
            this.testCount++
        }
        let command = file
        let trimmed = file.trimExt()

        if (file.extension == 'tst' && trimmed.extension == 'c') {
            if (options.projects) {
                buildProject(phase, topPath, file, env)
            }
            if (options.debug && Config.OS == 'macosx') {
                let proj = Path('testme').join(file.basename.trimExt().trimExt() + '-macosx-debug.xcodeproj')
                if (!proj.exists && !options.projects) {
                    buildProject(phase, topPath, file, env)
                }
                strace('Run', '/usr/bin/open ' + proj)
                Cmd.run('/usr/bin/open ' + proj)
                return false
            }
            if (options.projects) {
                return true
            }
        }
        if (options.clean || options.clobber) {
            clean(topPath, file)
            return true
        }
        try {
            command = buildTest(phase, topPath, file, env)
        } catch (e) {
            trace(phase, file + ' ... FAILED cannot build ' + topPath + '\n\n' + e.message)
            this.failedCount++
            return false
        }
        if (options.compile && !file.exension == 'set') {
            /* Must continue processing setup files */
            return true
        }
        let cont = true
        let prior = this.failedCount
        try {
            App.log.debug(5, serialize(env))
            this.startTest = new Date
            let cmd = new Cmd
            cmd.env = env
            strace('Run', command)
            cmd.start(command, blend({detach: true}, options))
            cmd.finalize()
            cmd.wait(TIMEOUT)
            if (cmd.status != 0) {
                trace(phase, file + ' ... FAILED with bad exit status ' + cmd.status)
                if (cmd.error) {
                    trace('Stderr', '\n' + cmd.error)
                }
                this.failedCount++
                cont = false
            } else {
                let output = cmd.readString()
                cont = parseOutput(phase, file, output, env)
                if (cmd.error) {
                    trace('Stderr', '\n' + cmd.error)
                }
            }
        } catch (e) {
            trace(phase, topPath + ' ... FAILED ' + e)
            this.failedCount++
            cont = false
        }
        if (prior == this.failedCount) {
            if (phase == 'Test') {
                trace(phase, topPath + ' ... PASSED')
            } else if (!options.verbose) {
                trace(phase, topPath)
            }
        } else {
            cont = false
        }
        return cont
    }

    function parseOutput(phase, file, output, env) {
        let success
        let lines = output.split('\n')
        for each (line in lines) {
            let tokens = line.trim().split(/ +/)
            let kind = tokens[0]
            let rest = tokens.slice(1).join(' ')
            switch (kind) {
            case 'fail':
                success = false
                this.failedCount++
                trace('Test', file + ' ... FAILED ' + rest)
                break
            case 'pass':
                success = true
                this.passedCount++
                break
            case 'info':
                if (success) {
                    vtrace('Info', rest)
                } else {
                    trace('Info', rest)
                }
                break
            case 'set':
                let parts = rest.split(' ')
                let key = parts[0]
                let value = parts.slice(1).join(' ')
                env[key] = value
                vtrace('Set', key, value)
                break
            case 'skip':
                success = true
                skippedCount++
                skipDirectory = true
                if (options.verbose || options.why) {
                    trace('Skip', file.dirname + ', ' + rest)
                }
                break
            case 'write':
                trace('Info', rest)
                break
            case '':
                break
            default:
                success = false
                this.failedCount++
                trace('Test', file + ' ... FAILED')
                trace('Stdout', '\n' + output)
                return false
            }
        }
        if (success == null) {
            /* Assume test passed if no result. Allows normal programs to be unit tests */
            this.passedCount++
            success = true
        }
        return keepGoing ? true : success
    }

    function createMakeMe(file: Path, env) {
        let name = file.trimExt().trimExt()
        let tm = Path('testme')
        tm.makeDir()
        tm.join('.GENERATED').write()
        let mefile = tm.join(name).joinExt('me')
        if (!mefile.exists) {
            let libraries = env.libraries ? env.libraries.split(/ /) : []
            libraries.push(Path('testme'))
            libraries = serialize(libraries).replace(/"/g, "'")
            let bin = cfg.join('bin').portable
            let inc = cfg.join('inc').portable
            let instructions = "
Me.load({
    configure: {
        requires: [ 'testme' ]
    },
    targets: {
        " + name + ": {
            type: 'exe',
            sources: [ '" + name + ".c' ],
            depends: [ 'testme' ],
            '+defines': [ 'BIN=\"" + bin + "\"' ],
            '+includes': [ '" + inc + "' ],
            '+libpaths': [ '" + bin + "' ],
            '+libraries': " + libraries + ",
            scripts: {
                prebuild: `
                    if (me.platform.like == 'unix') {
                        me.target.linker.push('-Wl,-rpath," + bin + "')
                        me.target.linker.push('-Wl,-rpath,' + me.dir.me.portable)
                    }
                `
            }
        }
    }
})
"
            Path(mefile).write(instructions)
        }
    }

    function clean(topPath, file) {
        let tm = Path('testme')
        let ext = file.trimExt().extension
        let name = file.trimExt().trimExt()
        let mefile = tm.join(name).joinExt('me')
        let c = tm.join(name).joinExt('c')
        let exe = tm.join(name)
        if (Config.OS == 'windows') {
            exe = exe.joinExt('.exe')
        }
        let base = topPath.dirname
        for each (f in tm.files(['*.o', '*.obj', '*.lib', '*.pdb', '*.exe', '*.mk', '*.sh', '*.mod'])) {
            trace('Remove', base.join(f))
            f.remove()
        }
        for each (f in tm.files([name + '-*.xcodeproj'])) {
            trace('Remove', base.join(f))
            f.removeAll()
        }
        if (exe && exe.exists) {
            exe.remove()
            trace('Remove', base.join(exe))
        }
        if (c.exists) {
            c.remove()
            trace('Remove', base.join(c))
        }
        if (options.clobber) {
            if (mefile.exists) {
                mefile.remove()
                trace('Remove', base.join(mefile))
            }
            if (tm.join('.GENERATED').exists) {
                tm.join('.GENERATED').remove()
                if (tm.remove()) {
                    trace('Remove', base.join(tm))
                }
            }
        }
    }

    /*
        Build the test and return the command to run
        For *.es, return a command with 'ejs' prepended
        For *.c, create a testme directory with *.me file
        For *.es.com, use 'ejsc' to precompile.

        Commands run from the directory containing the test.
     */
    function buildTest(phase, topPath: Path, file: Path, env): String? {
        let tm = Path('testme')
        let ext = file.trimExt().extension
        let name = file.trimExt().trimExt()
        let mefile = tm.join(name).joinExt('me')
        let c = tm.join(name).joinExt('c')

        let exe, command
        if (ext == 'es') {
            let mebin = Cmd.locate('me').dirname
            if (file.extension == 'com') {
                let ejsc = mebin.join('ejsc')
                let mod = tm.join(name).joinExt('mod', true)
                command = ejsc + ' --search "testme:' + mebin + '" --out ' + mod + ' ' + file
                tm.makeDir()
                if (options.rebuild || !mod.exists || mod.modified < file.modified) {
                    if (options.rebuild) {
                        why('Rebuild', mod + ' because --rebuild')
                    } else {
                        why('Rebuild', mod + ' because ' + file + ' is newer')
                    }
                } else {
                    why('Target', mod + ' is up to date')
                }
            } else {
                command = mebin.join('ejs') + ' --require ejs.testme ' + file
            }
        } else if (ext == 'c') {
            exe = tm.join(name)
            if (Config.OS == 'windows') {
                exe = exe.joinExt('.exe')
            }
            command = exe
            tm.makeDir()
            createMakeMe(file, env)
            if (options.rebuild) {
                why('Copy', 'Update ' + c + ' because --rebuild')
                file.copy(c)
            } else if (!c.exists || c.modified < file.modified) {
                why('Copy', 'Update ' + c + ' because ' + file + ' is newer')
                file.copy(c)
            }
            if (options.rebuild || !exe.exists || exe.modified < c.modified) {
                let show = options.show ? ' -s ' : ' '
                if (options.rebuild) {
                    why('Rebuild', exe + ' because --rebuild')
                } else {
                    why('Rebuild', exe + ' because ' + c + ' is newer')
                }
                strace('Build', 'me --chdir testme --file ' + mefile.basename + show)
                let result = Cmd.run('me --chdir testme --file ' + mefile.basename + show)
                if (options.show) {
                    log.write(result)
                }
            } else {
                why('Target', exe + ' is up to date')
            }
        }
        return command
    }

    function buildProject(phase, topPath, file: Path, env) {
        createMakeMe(file, env)
        let tm = Path('testme')
        let name = file.trimExt().trimExt()
        let mefile = tm.join(name).joinExt('me')
        trace('Generate', 'Projects ' + mefile.dirname.join(name))
        try {
            run('me --chdir ' + mefile.dirname + ' --file ' + mefile.basename + ' --name ' + name + ' generate')
        } catch (e) {
            trace(phase, file + ' ... FAILED cannot generate project for ' + topPath + '\n\n' + e.message)
        }
    }

    function summary() {
        if (!options.projects) {
            trace('Summary', ((failedCount == 0) ? 'PASSED' : 'FAILED') + ': ' + 
                failedCount + ' tests(s) failed, ' + 
                testCount + ' tests passed, ' + 
                skippedCount + ' tests(s) skipped. ' + 
                'Elapsed time ' + ('%.2f' % ((Date.now() - start) / 1000)) + ' secs.')
        }
    }

    function exit() {
        App.exit(failedCount > 0 ? 1 : 0)
    }

    function parseMeConfig(path: Path) {
        let data = Path(path).readString()
        let str = data.match(/ME_.*/g)
        for each (item in str) {
            let [key, value] = item.split(' ')
            key = key.replace(/ME_COM_/, '')
            key = key.replace(/ME_/, '').toUpperCase()
            if (value == '1' || value == '0') {
                value = value cast Number
            }
            topEnv['TM_' + key] = value
        }
        str = data.match(/export.*/g)
        env = {}
        for each (item in str) {
            if (!item.contains('=')) {
                continue
            }
            let [key, value] = item.split(':=')
            key = key.replace(/export /, '')
            env[key] = value
        }
    }

    function searchUp(path: Path): Path? {
        if (path.exists && !path.isDir) {
            return path
        }
        path = Path(path).relative
        dir = Path('..')
        while (true) {
            up = Path(dir.relative).join(path)
            if (up.exists && !up.isDir) {
                return up
            }
            if (dir.parent == dir) {
                break
            }
            dir = dir.parent
        }
        return null
    }

    function trace(tag: String, ...args): Void {
        log.activity(tag, ...args)
    }

    function strace(tag: String, ...args): Void {
        if (options.show) {
            log.activity(tag, ...args)
        }
    }

    function vtrace(tag: String, ...args): Void {
        if (verbosity > 0) {
            log.activity(tag, ...args)
        }
    }

    function why(tag: String, ...args): Void {
        if (options.why) {
            log.activity(tag, ...args)
        }
    }

    function run(cmd) {
        strace('Run', cmd)
        return Cmd.run(cmd)
    }
}

/*
    Main program
 */
var tm: TestMe = new TestMe

try {
    tm.parseArgs()
    tm.runAllTests()
} catch (e) { 
    App.log.error(e)
}
tm.summary()
tm.exit()

} /* module ejs.testme */

/*
    @copy   default

    Copyright (c) Embedthis Software LLC, 2003-2014. All Rights Reserved.

    This software is distributed under commercial and open source licenses.
    You may use the Embedthis Open Source license or you may acquire a 
    commercial license from Embedthis Software. You agree to be fully bound
    by the terms of either license. Consult the LICENSE.md distributed with
    this software for full details and other copyrights.

    Local variables:
    tab-width: 4
    c-basic-offset: 4
    End:
    vim: sw=4 ts=4 expandtab

    @end
 */
