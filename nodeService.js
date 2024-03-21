const Service = require('node-windows').Service

const svc = new Service({
    name: "ArtChat",
    description: "ArtChat backend",
    script: "C:\\HttpServer\\ArtChat\\index.js"
})

svc.on('install', function () {
    svc.start()
})

svc.install()