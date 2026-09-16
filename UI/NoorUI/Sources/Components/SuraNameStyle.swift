/// Controls how sura names are presented in sura and ayah references.
public enum SuraNameStyle: Equatable, Sendable {
    /// Localized text alongside the Arabic name; only the Arabic name in Arabic locales.
    case standard

    /// The localized name in regular letters and font in every locale.
    case text

    /// Localized text outside Arabic locales; Arabic in the decorated sura-name font in Arabic locales
    /// (or the reading's Quran font for IndoPak).
    case compact
}
