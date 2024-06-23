package data.util

import androidx.room.TypeConverter
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDateTime

class Converters {
    @TypeConverter
    fun fromTimestamp(value: String?): Instant? {
        return value?.let { Instant.parse(it) }
    }

    @TypeConverter
    fun dateToTimestamp(date: Instant?): String? {
        return date?.toString()
    }
}