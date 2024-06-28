package core.util.extensions

import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.format
import kotlinx.datetime.format.FormatStringsInDatetimeFormats
import kotlinx.datetime.format.byUnicodePattern

@OptIn(FormatStringsInDatetimeFormats::class)
// TODO: GET FROM SETTINGS AND PARSE MONTH AND DAY ACCORDINGLY
fun LocalDateTime.toUIString(): String {
    return this.format(
        LocalDateTime.Format {
            byUnicodePattern("yyyy/MM/dd - HH:mm")
        }
    )
}