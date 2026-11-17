//! Capability *candidates*, not device permission checks or tested support.

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CoreStatus {
    pub app_name: String,
    pub core_version: String,
    pub protocol_version: u32,
    pub platform: String,
    pub architecture: String,
    pub initialized: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RuntimeCapabilities {
    pub platform: String,
    pub architecture: String,
    pub local_network_candidate: bool,
    pub ble_api_candidate: bool,
    pub screen_capture_api_candidate: bool,
    pub remote_input_api_candidate: bool,
    pub native_apple_glass_candidate: bool,
    pub experimental: bool,
    pub note: String,
}

pub fn get_core_status() -> CoreStatus {
    CoreStatus {
        app_name: "OCIN".to_string(),
        core_version: env!("CARGO_PKG_VERSION").to_string(),
        protocol_version: 1,
        platform: std::env::consts::OS.to_string(),
        architecture: std::env::consts::ARCH.to_string(),
        initialized: true,
    }
}

pub fn detect_runtime_capabilities() -> RuntimeCapabilities {
    let os = std::env::consts::OS;
    let known_mobile_or_desktop = matches!(os, "macos" | "ios" | "android" | "windows" | "linux");
    RuntimeCapabilities {
        platform: os.to_string(),
        architecture: std::env::consts::ARCH.to_string(),
        local_network_candidate: known_mobile_or_desktop,
        ble_api_candidate: matches!(os, "macos" | "ios" | "android" | "windows"),
        screen_capture_api_candidate: matches!(os, "macos" | "ios" | "android" | "windows"),
        remote_input_api_candidate: matches!(os, "macos" | "android" | "windows"),
        // Native Liquid Glass requires an OS version + SDK + actual bridge probe.
        native_apple_glass_candidate: matches!(os, "macos" | "ios"),
        experimental: true,
        note: concat!(
            "OS-level candidates ONLY. No hardware, OS version, entitlement, ",
            "permission, or bridge probing has occurred."
        )
        .to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn status_identifies_app() {
        let s = get_core_status();
        assert_eq!(s.app_name, "OCIN");
        assert!(s.initialized);
        assert_eq!(s.protocol_version, 1);
        assert!(!s.core_version.is_empty());
    }

    #[test]
    fn capabilities_do_not_claim_real_device_support() {
        let c = detect_runtime_capabilities();
        assert!(c.experimental);
        assert!(c.note.contains("ONLY"));
        assert_eq!(c.platform, std::env::consts::OS);
    }
}
