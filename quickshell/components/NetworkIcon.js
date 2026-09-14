function icon(wired, wifi, problem) {
    if (!wired && !wifi) return "globe"
    if (problem) return wired ? "globe_warning" : "wifi_warning"
    return wired ? "desktop" : "wifi_1"
}
