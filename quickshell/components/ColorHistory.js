// Preview-only history. The cursor is persisted along with both undo and redo entries.
function record(history, value) {
    var entries = (history.entries || []).slice()
    var index = Number.isInteger(history.index) ? history.index : -1
    if (index >= 0 && JSON.stringify(entries[index]) === JSON.stringify(value))
        return {entries:entries,index:index}
    entries = entries.slice(0,index+1)
    entries.push(value)
    if (entries.length > 100) entries = entries.slice(-100)
    return {entries:entries,index:entries.length-1}
}
function move(history, delta) {
    return {entries:history.entries.slice(),index:Math.max(0,Math.min(history.entries.length-1,history.index+delta))}
}
