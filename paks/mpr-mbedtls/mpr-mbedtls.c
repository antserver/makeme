/*
    mpr-mbedtls.c - MbedTLS Interface to the MPR

    Individual sockets are not thread-safe. Must only be used by a single thread.

    Copyright (c) All Rights Reserved. See details at the end of the file.
 */

/********************************** Includes **********************************/

#include    "mpr.h"

#if ME_COM_MBEDTLS
 /*
    Indent to bypass MakeMe dependencies
  */
 #include    "mbedtls.h"

/************************************* Defines ********************************/
/*
    Per-route SSL configuration
 */
typedef struct MbedConfig {
    x509_crt            cert;           /* Certificate (own) */
    x509_crt            ca;             /* Certificate authority bundle to verify peer */
    x509_crl            revoke;         /* Certificate revoke list */
    ssl_cache_context   cache;          /* Session cache context */
    pk_context          pkey;           /* Private key */
    int                 *ciphers;       /* Set of acceptable ciphers - null terminated */
} MbedConfig;

/*
    Per socket state
 */
typedef struct MbedSocket {
    MbedConfig          *cfg;           /* Configuration */
    MprSocket           *sock;          /* MPR socket object */
    ctr_drbg_context    ctr;            /* Counter random generator state */
    ssl_context         ctx;            /* SSL state */
} MbedSocket;

static entropy_context  mbedEntropy;    /* Entropy context */
static int              logLevelBoost = 4;

static MprSocketProvider *mbedProvider; /* Mbedtls socket provider */

/***************************** Forward Declarations ***************************/

static int      checkPeerCertName(MprSocket *sp);
static void     closeMbed(MprSocket *sp, bool gracefully);
static void     disconnectMbed(MprSocket *sp);
static int      freeMbedLock(threading_mutex_t *tm);
static int      *getCipherSuite(cchar *ciphers, int *len);
static char     *getMbedState(MprSocket *sp);
static int      handshakeMbed(MprSocket *sp);
static int      initMbedLock(threading_mutex_t *tm);
static void     manageMbedConfig(MbedConfig *cfg, int flags);
static void     manageMbedProvider(MprSocketProvider *provider, int flags);
static void     manageMbedSocket(MbedSocket*ssp, int flags);
static int      mbedLock(threading_mutex_t *tm);
static void     mbedTerminator(int state, int how, int status);
static int      mbedUnlock(threading_mutex_t *tm);
static ssize    readMbed(MprSocket *sp, void *buf, ssize len);
static char     *replace(char *cipher, char from, char to);
static void     setSecured(MprSocket *sp);
static void     traceMbed(void *fp, int level, cchar *str);
static int      upgradeMbed(MprSocket *sp, MprSsl *sslConfig, cchar *peerName);
static ssize    writeMbed(MprSocket *sp, cvoid *buf, ssize len);

/************************************* Code ***********************************/
/*
    Create the Mbedtls module. This is called only once
 */
PUBLIC int mprSslInit(void *unused, MprModule *module)
{
    if ((mbedProvider = mprAllocObj(MprSocketProvider, manageMbedProvider)) == NULL) {
        return MPR_ERR_MEMORY;
    }
    mbedProvider->name = sclone("mbedtls");
    mbedProvider->upgradeSocket = upgradeMbed;
    mbedProvider->closeSocket = closeMbed;
    mbedProvider->disconnectSocket = disconnectMbed;
    mbedProvider->readSocket = readMbed;
    mbedProvider->writeSocket = writeMbed;
    mbedProvider->socketState = getMbedState;
    mprSetSslProvider(mbedProvider);
    mprAddTerminator(mbedTerminator);

    threading_set_alt(initMbedLock, freeMbedLock, mbedLock, mbedUnlock);
    entropy_init(&mbedEntropy);

    if (mprGetLogLevel() >= 5) {
        char    cipher[80];
        cint    *cp;
        mprLog("info mbedtls", 5, "Supported Ciphers");
        for (cp = ssl_list_ciphersuites(); *cp; cp++) {
            scopy(cipher, sizeof(cipher), ssl_get_ciphersuite_name(*cp));
            replace(cipher, '-', '_');
            mprLog("info mbedtls", 5, "%s (0x%04X)", cipher, *cp);
        }
    }
    return 0;
}


void terminateMbed()
{
    entropy_free(&mbedEntropy);
}


static void mbedTerminator(int state, int how, int status)
{
    if (state >= MPR_STOPPED) {
        terminateMbed();
    }
}


static void manageMbedProvider(MprSocketProvider *provider, int flags)
{
    if (flags & MPR_MANAGE_MARK) {
        mprMark(provider->name);

    } else if (flags & MPR_MANAGE_FREE) {
        ;
    }
}


static void manageMbedConfig(MbedConfig *cfg, int flags)
{
    if (flags & MPR_MANAGE_MARK) {
        mprMark(cfg->ciphers);

    } else if (flags & MPR_MANAGE_FREE) {
        pk_free(&cfg->pkey);
        x509_crt_free(&cfg->cert);
        x509_crt_free(&cfg->ca);
        x509_crl_free(&cfg->revoke);
        ssl_cache_free(&cfg->cache);
    }
}


/*
    Destructor for an MbedSocket object
 */
static void manageMbedSocket(MbedSocket *mb, int flags)
{
    if (flags & MPR_MANAGE_MARK) {
        mprMark(mb->cfg);
        mprMark(mb->sock);

    } else if (flags & MPR_MANAGE_FREE) {
        ssl_free(&mb->ctx);
        ctr_drbg_free(&mb->ctr);
    }
}


static void closeMbed(MprSocket *sp, bool gracefully)
{
    MbedSocket      *mb;

    mb = sp->sslSocket;
    sp->service->standardProvider->closeSocket(sp, gracefully);
    if (!(sp->flags & MPR_SOCKET_EOF)) {
        ssl_close_notify(&mb->ctx);
    }
}


/*
    Create and initialize an SSL configuration for a route. This configuration is used by all requests for
    a given route. An application can have different SSL configurations for different routes. There is also
    a default SSL configuration that is used when a route does not define a configuration and one for clients.
 */
static MbedConfig *createMbedConfig(MprSocket *sp)
{
    MprSsl      *ssl;
    MbedConfig  *cfg;

    ssl = sp->ssl;
    assert(ssl);

    /*
        One time setup for the SSL configuration for this MprSsl
     */
    if ((cfg = mprAllocObj(MbedConfig, manageMbedConfig)) == 0) {
        return 0;
    }
    pk_init(&cfg->pkey);
    ssl_cache_init(&cfg->cache);

    if (ssl->certFile) {
        /*
            Load a PEM format certificate file
         */
        if (x509_crt_parse_file(&cfg->cert, (char*) ssl->certFile) != 0) {
            sp->errorMsg = sfmt("Unable to parse certificate %s", ssl->certFile); 
            return 0;
        }
    }
    if (ssl->keyFile) {
        /*
            Load a decrypted PEM format private key
            Last arg is password if you need to use an encrypted private key
         */
        if (pk_parse_keyfile(&cfg->pkey, (char*) ssl->keyFile, 0) != 0) {
            sp->errorMsg = sfmt("Unable to parse key file %s", ssl->keyFile); 
            return 0;
        }
    }
    if (ssl->verifyPeer) {
        if (!ssl->caFile) {
            sp->errorMsg = sclone("No defined certificate authority file");
            return 0;
        }
        if (x509_crt_parse_file(&cfg->ca, (char*) ssl->caFile) != 0) {
            sp->errorMsg = sfmt("Unable to open or parse certificate authority file %s", ssl->caFile); 
            return 0;
        }
    }
    if (ssl->revoke) {
        /*
            Load a PEM format certificate file
         */
        if (x509_crl_parse_file(&cfg->revoke, (char*) ssl->revoke) != 0) {
            sp->errorMsg = sfmt("Unable to parse revoke list %s", ssl->revoke); 
            return 0;
        }
    }
    cfg->ciphers = getCipherSuite(ssl->ciphers, NULL);
    logLevelBoost = ssl->logLevel;
    return cfg;
}


/*
    Upgrade a standard socket to use TLS
 */
static int upgradeMbed(MprSocket *sp, MprSsl *ssl, cchar *peerName)
{
    MbedSocket      *mb;
    MbedConfig      *cfg;
    ssl_context     *ctx;
    cchar           *name;
    int             rc;

    assert(sp);

    if (ssl == 0) {
        ssl = mprCreateSsl(sp->flags & MPR_SOCKET_SERVER);
    }
    sp->ssl = ssl;

    if (ssl->config && !ssl->changed) {
        cfg = ssl->config;
    } else {
        /*
            On-demand creation of the SSL configuration
         */
        if ((cfg = createMbedConfig(sp)) == 0) {
            return MPR_ERR_CANT_INITIALIZE;
        }
        ssl->config = cfg;
        ssl->changed = 0;
    }

    if ((mb = (MbedSocket*) mprAllocObj(MbedSocket, manageMbedSocket)) == 0) {
        return MPR_ERR_MEMORY;
    }
    sp->sslSocket = mb;
    mb->cfg = cfg;
    mb->sock = sp;

    ctx = &mb->ctx;
    rc = 0;

    /*
        Order matters in these various initialization calls.
        Endpoint must be defined first and rng early.
     */
    rc += ssl_init(ctx);
    ssl_set_endpoint(ctx, sp->flags & MPR_SOCKET_SERVER ? SSL_IS_SERVER : SSL_IS_CLIENT);
    ssl_set_dbg(ctx, traceMbed, NULL);

    name = mprGetAppName();
    rc += ctr_drbg_init(&mb->ctr, entropy_func, &mbedEntropy, (cuchar*) name, slen(name));
    ssl_set_rng(ctx, ctr_drbg_random, &mb->ctr);

    /*
        Configure larger DH parameters 
     */
    rc += ssl_set_dh_param(ctx, POLARSSL_DHM_RFC5114_MODP_2048_P, POLARSSL_DHM_RFC5114_MODP_2048_G);

    /*
        Configure ticket-based sessions
     */
    if (sp->flags & MPR_SOCKET_SERVER) {
        if (ssl->ticket) {
            rc += ssl_set_session_tickets(ctx, 1);
            ssl_set_session_ticket_lifetime(ctx, (int) ssl->sessionTimeout / TPS);
        }
    }

    /*
        Set auth mode if peer cert should be verified
     */
    ssl_set_authmode(ctx, ssl->verifyPeer ? SSL_VERIFY_OPTIONAL : SSL_VERIFY_NONE);

    ssl_set_bio(ctx, net_recv, &sp->fd, net_send, &sp->fd);

    /*
        Disable insecure RC4
     */
    ssl_set_arc4_support(ctx, SSL_ARC4_DISABLED);

    /*
        Configure server-side session cache
     */
    if (ssl->cacheSize > 0) {
        ssl_set_session_cache(ctx, ssl_cache_get, &cfg->cache, ssl_cache_set, &cfg->cache);
        ssl_cache_set_max_entries(&cfg->cache, ssl->cacheSize);
        ssl_cache_set_timeout(&cfg->cache, (int) (ssl->sessionTimeout / TPS));
    }

    /*
        Configure explicit cipher suite selection
     */
    if (cfg->ciphers) {
        ssl_set_ciphersuites(ctx, cfg->ciphers);
    }

    /*
        Configure CA certificate bundle and revocation list and optional expected peer name
     */
    ssl_set_ca_chain(ctx, ssl->caFile ? &cfg->ca : NULL, ssl->revoke ? &cfg->revoke : NULL, (char*) peerName);

    /*
        Configure server cert and key
     */
    if (ssl->keyFile && ssl->certFile) {
        rc += ssl_set_own_cert(ctx, &cfg->cert, &cfg->pkey);
    }
    if (rc < 0) {
        mprLog("error mbedtls ssl", 0, "Cannot initialize MbedTLS");
        return -1;
    }
    if (handshakeMbed(sp) < 0) {
        return -1;
    }
    return 0;
}


static void disconnectMbed(MprSocket *sp)
{
    sp->service->standardProvider->disconnectSocket(sp);
}


/*
    Initiate or continue SSL handshaking with the peer. This routine does not block.
    Return -1 on errors, 0 incomplete and awaiting I/O, 1 if successful
 */
static int handshakeMbed(MprSocket *sp)
{
    MbedSocket  *mb;
    int         rc, vrc;

    mb = (MbedSocket*) sp->sslSocket;
    assert(!(mb->ctx.state == SSL_HANDSHAKE_OVER));

    rc = 0;
    sp->flags |= MPR_SOCKET_HANDSHAKING;
    while (mb->ctx.state != SSL_HANDSHAKE_OVER && (rc = ssl_handshake(&mb->ctx)) != 0) {
        if (rc == POLARSSL_ERR_NET_WANT_READ || rc == POLARSSL_ERR_NET_WANT_WRITE)  {
            if (!mprGetSocketBlockingMode(sp)) {
                return 0;
            }
            continue;
        }
        /* Error */
        break;
    }
    sp->flags &= ~MPR_SOCKET_HANDSHAKING;

    /*
        Analyze the handshake result
     */
    if (rc < 0) {
        if (rc == POLARSSL_ERR_SSL_PRIVATE_KEY_REQUIRED && !(sp->ssl->keyFile || sp->ssl->certFile)) {
            sp->errorMsg = sclone("Peer requires a certificate");
        } else {
            sp->errorMsg = sfmt("Cannot handshake: error -0x%x", -rc);
        }
        sp->flags |= MPR_SOCKET_EOF;
        errno = EPROTO;
        return -1;
    } 
    if ((vrc = ssl_get_verify_result(&mb->ctx)) != 0) {
        if (vrc & BADCERT_MISSING) {
            sp->errorMsg = sclone("Certificate missing");

        } if (vrc & BADCERT_EXPIRED) {
            sp->errorMsg = sclone("Certificate expired");

        } else if (vrc & BADCERT_REVOKED) {
            sp->errorMsg = sclone("Certificate revoked");

        } else if (vrc & BADCERT_CN_MISMATCH) {
            sp->errorMsg = sclone("Certificate common name mismatch");

        } else if (vrc & BADCERT_KEY_USAGE || vrc & BADCERT_EXT_KEY_USAGE) {
            sp->errorMsg = sclone("Unauthorized key use in certificate");

        } else if (vrc & BADCERT_NOT_TRUSTED) {
            sp->errorMsg = sclone("Certificate not trusted");
            if (!sp->ssl->verifyIssuer) {
                vrc = 0;
            }

        } else if (vrc & BADCERT_SKIP_VERIFY) {
            /* 
                SSL_VERIFY_NONE requested, so ignore error
             */
            vrc = 0;

        } else {
            if (mb->ctx.client_auth && !sp->ssl->certFile) {
                sp->errorMsg = sclone("Server requires a client certificate");
            } else if (rc == POLARSSL_ERR_NET_CONN_RESET) {
                sp->errorMsg = sclone("Peer disconnected");
            } else {
                sp->errorMsg = sfmt("Cannot handshake: error -0x%x", -rc);
            }
        }
    }
    if (vrc != 0 && sp->ssl->verifyPeer) {
        if (ssl_get_peer_cert(&mb->ctx) == 0) {
            sp->errorMsg = sclone("Peer did not provide a certificate");
        }
        sp->flags |= MPR_SOCKET_EOF;
        errno = EPROTO;
        return -1;
    }
    if (checkPeerCertName(sp) < 0) {
        return MPR_ERR_CANT_CONNECT;
    }
    setSecured(sp);
    return 1;
}


static int checkPeerCertName(MprSocket *sp)
{
    MbedSocket      *mb;
    const x509_crt  *peer;
    char            cbuf[5120], *cp, *end;

    mb = (MbedSocket*) sp->sslSocket;
    /*
        Get peer details
     */
    if ((peer = ssl_get_peer_cert(&mb->ctx)) != 0) {
        if (mprGetLogLevel() >= 5) {
            char buf[4096];
            x509_crt_info(buf, sizeof(buf) - 1, "", peer);
            mprLog("info mbedtls", 5, "Peer certificate\n%s", buf);
        }
        x509_dn_gets(cbuf, sizeof(cbuf), &peer->subject);
        sp->peerCert = sclone(cbuf);
        /*
            Extract the common name for the peer name
         */
        if ((cp = scontains(cbuf, "CN=")) != 0) {
            cp += 3;
            if ((end = schr(cp, ',')) != 0) {
                sp->peerName = snclone(cp, end - cp);
            }
        }
        x509_dn_gets(cbuf, sizeof(cbuf), &peer->issuer);
        sp->peerCertIssuer = sclone(cbuf);
    }
    return 0;
}


/*
    Return the number of bytes read. Return -1 on errors and EOF. Distinguish EOF via mprIsSocketEof.
    If non-blocking, may return zero if no data or still handshaking.
 */
static ssize readMbed(MprSocket *sp, void *buf, ssize len)
{
    MbedSocket  *mb;
    int         rc;

    mb = (MbedSocket*) sp->sslSocket;
    assert(mb);
    assert(mb->cfg);

    if (sp->fd == INVALID_SOCKET) {
        return -1;
    }
    if (mb->ctx.state != SSL_HANDSHAKE_OVER) {
        if ((rc = handshakeMbed(sp)) <= 0) {
            return rc;
        }
    }
    while (1) {
        rc = ssl_read(&mb->ctx, buf, (int) len);
        mprDebug("debug mpr ssl mbedtls", 5, "ssl_read %d", rc);
        if (rc < 0) {
            if (rc == POLARSSL_ERR_NET_WANT_READ || rc == POLARSSL_ERR_NET_WANT_WRITE)  {
                rc = 0;
                break;

            } else if (rc == POLARSSL_ERR_SSL_PEER_CLOSE_NOTIFY) {
                mprDebug("debug mpr ssl mbedtls", 5, "connection was closed gracefully\n");
                sp->flags |= MPR_SOCKET_EOF;
                return -1;

            } else {
                mprDebug("debug mpr ssl mbedtls", 4, "readMbed: error -0x%x", -rc);
                sp->flags |= MPR_SOCKET_EOF;
                return -1;
            }
        } else if (rc == 0) {
            sp->flags |= MPR_SOCKET_EOF;
            return -1;
        }
        break;
    }
    mprHiddenSocketData(sp, ssl_get_bytes_avail(&mb->ctx), MPR_READABLE);
    return rc;
}


/*
    Write data. Return the number of bytes written or -1 on errors or socket closure.
    If non-blocking, may return zero if no data or still handshaking.
 */
static ssize writeMbed(MprSocket *sp, cvoid *buf, ssize len)
{
    MbedSocket  *mb;
    ssize       totalWritten;
    int         rc;

    mb = (MbedSocket*) sp->sslSocket;
    if (len <= 0) {
        assert(0);
        return -1;
    }
    if (mb->ctx.state != SSL_HANDSHAKE_OVER) {
        if ((rc = handshakeMbed(sp)) <= 0) {
            return rc;
        }
    }
    totalWritten = 0;
    rc = 0;
    do {
        rc = ssl_write(&mb->ctx, (uchar*) buf, (int) len);
        mprDebug("debug mpr ssl mbedtls", 6, "writeMbed written %d, requested len %zd", rc, len);
        if (rc <= 0) {
            if (rc == POLARSSL_ERR_NET_WANT_READ || rc == POLARSSL_ERR_NET_WANT_WRITE) {
                break;
            }
            if (rc == POLARSSL_ERR_NET_CONN_RESET) {                                                         
                mprDebug("debug mpr ssl mbedtls", 5, "ssl_write peer closed");
                return -1;
            } else {
                mprDebug("debug mpr ssl mbedtls", 5, "ssl_write failed rc -0x%x", -rc);
                return -1;
            }
        } else {
            totalWritten += rc;
            buf = (void*) ((char*) buf + rc);
            len -= rc;
            mprDebug("debug mpr ssl mbedtls", 6, "writeMbed: len %zd, written %d, total %zd", len, rc, totalWritten);
        }
    } while (len > 0);

    mprHiddenSocketData(sp, mb->ctx.out_left, MPR_WRITABLE);

    if (totalWritten == 0 && (rc == POLARSSL_ERR_NET_WANT_READ || rc == POLARSSL_ERR_NET_WANT_WRITE))  {
        mprSetError(EAGAIN);
        return -1;
    }
    return totalWritten;
}


/*
    Set the socket into a secured state. Capture the session ID.
 */
static void setSecured(MprSocket *sp)
{
    MbedSocket      *mb;
    MprBuf          *buf;
    ssize           len;
    int             i;

    mb = sp->sslSocket;
    sp->secured = 1;
    sp->cipher = replace(sclone(ssl_get_ciphersuite(&mb->ctx)), '-', '_');

    /*
        Convert session into a string
     */
    len = mb->ctx.session->length;
    if (len > 0) {
        buf = mprCreateBuf(len, 0);
        for (i = 0; i < len; i++) {
            mprPutToBuf(buf, "%02X", (uchar) mb->ctx.session->id[i]);
        }
        sp->session = mprBufToString(buf);
    } else if (mb->ctx.ticket_keys) {
        sp->session = sclone("ticket");
    }
}


static void removeSpaces(char *buf)
{
    char    *ip, *op;

    for (op = ip = buf; *ip; ip++) {
        if (*ip == ' ') {
            continue;
        }
        if (ip > buf && ip[-1] == ' ') {
            *op++ = toupper((uchar) *ip);
        } else if (*ip == '\n') {
            *op++ = ',';
        } else {
            *op++ = *ip;
        }
    }
    *op++ = '\0';
}


/*
    Called to log the MbedTLS socket / certificate state
 */
static char *getMbedState(MprSocket *sp)
{
    MbedSocket      *mb;
    ssl_context     *ctx;
    ssl_session     *session;
    MprBuf          *buf;
    char            *ownPrefix, *peerPrefix;
    char            cbuf[5120];

    if ((mb = sp->sslSocket) == 0) {
        return 0;
    }
    ctx = &mb->ctx;
    session = ctx->session;
    buf = mprCreateBuf(0, 0);
    mprPutToBuf(buf, "PROVIDER=mbedtls,CIPHER=%s,SESSION=%s,", ssl_get_ciphersuite(ctx), sp->session);

    mprPutToBuf(buf, "PEER=\"%s\",", sp->peerName);
    if (session->peer_cert) {
        peerPrefix = sp->acceptIp ? "CLIENT_" : "SERVER_";
        x509_crt_info(cbuf, sizeof(cbuf), peerPrefix, session->peer_cert);
        removeSpaces(cbuf);
        mprPutStringToBuf(buf, cbuf);
    } else {
        mprPutToBuf(buf, "%s=\"none\",", sp->acceptIp ? "CLIENT_CERT" : "SERVER_CERT");
    }
    if (ctx->key_cert && ctx->key_cert->cert) {
        ownPrefix =  sp->acceptIp ? "SERVER_" : "CLIENT_";
        x509_crt_info(cbuf, sizeof(cbuf), ownPrefix, ctx->key_cert->cert);
        removeSpaces(cbuf);
        mprPutStringToBuf(buf, cbuf);
    }
    return mprGetBufStart(buf);
}


/*
    Convert string of IANA ciphers into a list of cipher codes
 */
static int *getCipherSuite(cchar *ciphers, int *len)
{
    char    *cipher, *next;
    cint    *cp;
    int     nciphers, i, *result, code;

    if (!ciphers || *ciphers == 0) {
        return 0;
    }
    for (nciphers = 0, cp = ssl_list_ciphersuites(); cp && *cp; cp++, nciphers++) { }
    result = mprAlloc((nciphers + 1) * sizeof(int));

    next = sclone(ciphers);
    for (i = 0; (cipher = stok(next, ":, \t", &next)) != 0; ) {
        replace(cipher, '_', '-');
        if ((code = ssl_get_ciphersuite_id(cipher)) <= 0) {
            mprLog("error mpr", 0, "Unsupported cipher \"%s\"", cipher);
            continue;
        }
        result[i++] = code;
    }
    result[i] = 0;
    if (len) {
        *len = i;
    }
    return result;
}


static int initMbedLock(threading_mutex_t *tm)
{
    MprMutex    *lock;

    lock = mprCreateLock();
    mprHold(lock);
    *tm = lock;
    return 0;
}


static int freeMbedLock(threading_mutex_t *tm)
{
    mprRelease(*tm);
    return 0;
}


static int mbedLock(threading_mutex_t *tm)
{
    mprLock(*tm);
    return 0;
}


static int mbedUnlock(threading_mutex_t *tm)
{
    mprUnlock(*tm);
    return 0;
}


/*
    Trace from within MbedTLS
 */
static void traceMbed(void *fp, int level, cchar *str)
{
    level += logLevelBoost;
    if (level <= MPR->logLevel) {
        mprLog("info mbedtls", level, "%s: %d: %s", MPR->name, level, str);
    }
}


static char *replace(char *cipher, char from, char to)
{
    char    *cp;

    for (cp = cipher; *cp; cp++) {
        if (*cp == from) {
            *cp = to;
        }
    }
    return cipher;
}

#endif /* ME_COM_MBEDTLS */

/*
    @copy   default

    Copyright (c) Embedthis Software. All Rights Reserved.

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
