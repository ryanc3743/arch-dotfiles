.pragma library

function parse(text) {
    var cpu = /^cpu\s+(.+)$/m.exec(text)
    var total = /^MemTotal:\s+(\d+)\s+kB$/m.exec(text)
    var available = /^MemAvailable:\s+(\d+)\s+kB$/m.exec(text)
    var uptime = /^(\d+(?:\.\d+)?)\s+\d+(?:\.\d+)?\s*$/m.exec(text)
    if (!cpu || !total || !available || !uptime) return null
    var counters = cpu[1].trim().split(/\s+/).slice(0, 8).map(Number)
    if (counters.length < 8 || counters.some(v => !isFinite(v) || v < 0)) return null
    var memoryTotal = Number(total[1])
    var memoryAvailable = Number(available[1])
    if (memoryTotal <= 0 || memoryAvailable > memoryTotal) return null
    return {
        // Guest counters are already included in user/nice; do not count them twice.
        total: counters.reduce((sum, value) => sum + value, 0),
        idle: counters[3] + counters[4],
        memoryTotal: memoryTotal,
        memoryUsed: memoryTotal - memoryAvailable,
        uptime: Number(uptime[1])
    }
}

function cpuPercent(previous, current) {
    if (!previous || !current) return -1
    var elapsed = current.total - previous.total
    var idle = current.idle - previous.idle
    if (elapsed <= 0 || idle < 0 || idle > elapsed) return -1
    return Math.round(100 * (elapsed - idle) / elapsed)
}

function uptimeText(seconds) {
    var minutes = Math.floor(seconds / 60)
    var hours = Math.floor(minutes / 60)
    var days = Math.floor(hours / 24)
    return (days ? days + "d " : "") + (hours % 24) + "h " + (minutes % 60) + "m"
}
