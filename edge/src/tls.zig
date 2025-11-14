const std = @import("std");
const c = @cImport({
    @cInclude("mbedtls/ssl.h");
    @cInclude("mbedtls/net_sockets.h");
    @cInclude("mbedtls/entropy.h");
    @cInclude("mbedtls/ctr_drbg.h");
    @cInclude("mbedtls/error.h");
    @cInclude("mbedtls/certs.h");
});

pub const TLSError = error{
    InitFailed,
    HandshakeFailed,
    ReadFailed,
    WriteFailed,
    CertificateError,
    ConfigError,
    LoadCertFailed,
    LoadKeyFailed,
};

pub const TLSContext = struct {
    allocator: std.mem.Allocator,
    config: TLSConfig,
    ssl: c.mbedtls_ssl_context,
    conf: c.mbedtls_ssl_config,
    server_fd: c.mbedtls_net_context,
    entropy: c.mbedtls_entropy_context,
    ctr_drbg: c.mbedtls_ctr_drbg_context,
    initialized: bool,

    pub const TLSConfig = struct {
        ca_cert_path: ?[]const u8,
        client_cert_path: ?[]const u8,
        client_key_path: ?[]const u8,
        verify_peer: bool,
    };

    pub fn init(allocator: std.mem.Allocator, config: TLSConfig) !TLSContext {
        var ctx = TLSContext{
            .allocator = allocator,
            .config = config,
            .ssl = undefined,
            .conf = undefined,
            .server_fd = undefined,
            .entropy = undefined,
            .ctr_drbg = undefined,
            .initialized = false,
        };

        c.mbedtls_ssl_init(&ctx.ssl);
        c.mbedtls_ssl_config_init(&ctx.conf);
        c.mbedtls_net_init(&ctx.server_fd);
        c.mbedtls_entropy_init(&ctx.entropy);
        c.mbedtls_ctr_drbg_init(&ctx.ctr_drbg);

        const pers = "microkernel_tls";
        const ret = c.mbedtls_ctr_drbg_seed(&ctx.ctr_drbg, c.mbedtls_entropy_func, &ctx.entropy, pers.ptr, pers.len);
        if (ret != 0) {
            ctx.deinit();
            return error.InitFailed;
        }

        const ret2 = c.mbedtls_ssl_config_defaults(&ctx.conf, c.MBEDTLS_SSL_IS_CLIENT, c.MBEDTLS_SSL_TRANSPORT_STREAM, c.MBEDTLS_SSL_PRESET_DEFAULT);
        if (ret2 != 0) {
            ctx.deinit();
            return error.ConfigError;
        }

        c.mbedtls_ssl_conf_rng(&ctx.conf, c.mbedtls_ctr_drbg_random, &ctx.ctr_drbg);

        if (ctx.config.verify_peer) {
            c.mbedtls_ssl_conf_authmode(&ctx.conf, c.MBEDTLS_SSL_VERIFY_REQUIRED);
        } else {
            c.mbedtls_ssl_conf_authmode(&ctx.conf, c.MBEDTLS_SSL_VERIFY_OPTIONAL);
        }

        if (ctx.config.ca_cert_path) |ca_path| {
            var ca_cert: c.mbedtls_x509_crt = undefined;
            c.mbedtls_x509_crt_init(&ca_cert);
            const ret3 = c.mbedtls_x509_crt_parse_file(&ca_cert, std.mem.span(ca_path).ptr);
            if (ret3 != 0) {
                c.mbedtls_x509_crt_free(&ca_cert);
                ctx.deinit();
                return error.LoadCertFailed;
            }
            c.mbedtls_ssl_conf_ca_chain(&ctx.conf, &ca_cert, null);
        }

        if (ctx.config.client_cert_path) |cert_path| {
            var client_cert: c.mbedtls_x509_crt = undefined;
            var client_key: c.mbedtls_pk_context = undefined;
            c.mbedtls_x509_crt_init(&client_cert);
            c.mbedtls_pk_init(&client_key);

            const ret4 = c.mbedtls_x509_crt_parse_file(&client_cert, std.mem.span(cert_path).ptr);
            if (ret4 != 0) {
                c.mbedtls_x509_crt_free(&client_cert);
                c.mbedtls_pk_free(&client_key);
                ctx.deinit();
                return error.LoadCertFailed;
            }

            if (ctx.config.client_key_path) |key_path| {
                const ret5 = c.mbedtls_pk_parse_keyfile(&client_key, std.mem.span(key_path).ptr, null);
                if (ret5 != 0) {
                    c.mbedtls_x509_crt_free(&client_cert);
                    c.mbedtls_pk_free(&client_key);
                    ctx.deinit();
                    return error.LoadKeyFailed;
                }
            }

            c.mbedtls_ssl_conf_own_cert(&ctx.conf, &client_cert, &client_key);
        }

        const ret6 = c.mbedtls_ssl_setup(&ctx.ssl, &ctx.conf);
        if (ret6 != 0) {
            ctx.deinit();
            return error.InitFailed;
        }

        ctx.initialized = true;
        return ctx;
    }

    pub fn deinit(self: *TLSContext) void {
        if (self.initialized) {
            c.mbedtls_ssl_free(&self.ssl);
            c.mbedtls_ssl_config_free(&self.conf);
            c.mbedtls_net_free(&self.server_fd);
            c.mbedtls_entropy_free(&self.entropy);
            c.mbedtls_ctr_drbg_free(&self.ctr_drbg);
            self.initialized = false;
        }
    }

    pub fn connect(self: *TLSContext, socket: std.net.Stream, hostname: []const u8) !void {
        if (!self.initialized) return error.InitFailed;

        self.server_fd.fd = @intCast(socket.handle);
        const ret = c.mbedtls_ssl_set_hostname(&self.ssl, hostname.ptr);
        if (ret != 0) return error.ConfigError;

        c.mbedtls_ssl_set_bio(&self.ssl, &self.server_fd, c.mbedtls_net_send, c.mbedtls_net_recv, null);

        while (true) {
            const ret2 = c.mbedtls_ssl_handshake(&self.ssl);
            if (ret2 == 0) break;
            if (ret2 != c.MBEDTLS_ERR_SSL_WANT_READ and ret2 != c.MBEDTLS_ERR_SSL_WANT_WRITE) {
                return error.HandshakeFailed;
            }
        }

        const verify_result = c.mbedtls_ssl_get_verify_result(&self.ssl);
        if (verify_result != 0 and self.config.verify_peer) {
            return error.CertificateError;
        }
    }

    pub fn read(self: *TLSContext, buffer: []u8) !usize {
        if (!self.initialized) return error.InitFailed;

        const ret = c.mbedtls_ssl_read(&self.ssl, buffer.ptr, buffer.len);
        if (ret < 0) {
            if (ret == c.MBEDTLS_ERR_SSL_WANT_READ or ret == c.MBEDTLS_ERR_SSL_WANT_WRITE) {
                return 0;
            }
            return error.ReadFailed;
        }
        return @intCast(ret);
    }

    pub fn write(self: *TLSContext, data: []const u8) !usize {
        if (!self.initialized) return error.InitFailed;

        const ret = c.mbedtls_ssl_write(&self.ssl, data.ptr, data.len);
        if (ret < 0) {
            if (ret == c.MBEDTLS_ERR_SSL_WANT_READ or ret == c.MBEDTLS_ERR_SSL_WANT_WRITE) {
                return 0;
            }
            return error.WriteFailed;
        }
        return @intCast(ret);
    }
};
