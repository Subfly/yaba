package data.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "folders_table")
data class FolderEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "folder_id")
    val id: Long = 0,
    var name: String = "",
    var iconName: String? = null,
    var firstColor: String? = null,
    var secondColor: String? = null,
)
