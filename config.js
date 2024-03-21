const sqlConfig = {
    user: 'WebApi',
    password: 'P@$$w0rd',
    database: 'ArtChat',
    server: '78.188.46.105\\Sanyar', //192.168.1.254
    port: 8090,
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    },
    options: {
        encrypt: true, // for azure
        trustServerCertificate: true // change to true for local dev / self-signed certs
    }
}


module.exports = {
    sqlConfig
}
