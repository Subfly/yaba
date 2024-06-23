package data.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "tags_table",
    indices = [
        Index(value = ["tag_id"]),
    ]
)
data class TagEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "tag_id")
    val id: Long = 0,
    var name: String = "",
    var iconName: String? = null,
    var firstColor: String? = null,
    var secondColor: String? = null,
)
