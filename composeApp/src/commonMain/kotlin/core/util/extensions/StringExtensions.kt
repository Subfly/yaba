package core.util.extensions

fun String.isValidUrl(): Boolean {
    val regex = ("^(https?|ftp)://"
            + "(([\\w.-]+)+(:\\d+)?"
            + "(/([\\w/_.-]*(\\?\\S+)?)?)?)$").toRegex()
    return regex.matches(this)
}
