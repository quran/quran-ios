/// Controls how sura names are presented in sura and ayah references.
public enum SuraNameStyle: Equatable, Sendable {
    /// The localized name in regular letters and font in every locale. The default everywhere.
    case text

    /// The localized name alongside the decorated Arabic name outside Arabic locales; only the decorated
    /// Arabic name in Arabic locales (the reading's Quran font instead of the sura-name font for IndoPak).
    /// Reserved for the home Surahs and Juz' lists and the translation pages' sura banner.
    case decorated
}
