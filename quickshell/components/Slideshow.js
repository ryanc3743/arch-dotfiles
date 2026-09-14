// Ordered traversal follows the gallery model; random traversal avoids immediate repeats.
function nextIndex(length, current, randomOrder, randomValue) {
    if (length <= 0) return -1
    if (length === 1) return 0
    if (!randomOrder) return (current + 1) % length
    var value = Math.max(0, Math.min(0.999999999, randomValue))
    if (current < 0 || current >= length) return Math.floor(value * length)
    var next = Math.floor(value * (length - 1))
    return next >= current ? next + 1 : next
}
