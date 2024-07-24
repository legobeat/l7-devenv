pref("browser.contentblocking.category", "strict");

pref("extensions.pocket.enabled", false);
pref("extensions.pocket.showHome", false);
pref("extensions.pocket.onSaveRecs", false);

// re-enable system-wide extensions
pref("extensions.enabledScopes", 13);
// auto-enable system-wide extensions
pref("extensions.autoDisableScopes", 7);

// to enable cleartext to internal eth rpc (dshackle)
// can disable if that is made https
pref("dom.security.https_only_mode", false);

// * 0=blank, 1=home, 2=last visited page, 3=resume previous session
pref("browser.startup.page", 3);
// pref("browser.startup.page", 1);
// pref("browser.startup.homepage", "https://home.gw1.internal");

// Disable DoT
pref("network.trr.mode", 5);

// allow mitm cert
pref("security.OCSP.require", false);
pref("security.cert_pinning.enforcement_level", 1);

pref("privacy.clearOnShutdown.history", false);
pref("privacy.clearOnShutdown.sessions", false);
pref("privacy.clearOnShutdown.downloads", false);
