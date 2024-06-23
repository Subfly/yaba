package view.mobile.creation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.SheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import core.components.layout.YabaModalSheet
import view.mobile.creation.components.CreateOrEditBookmarkContent
import view.mobile.creation.components.CreateOrEditFolderContent
import view.mobile.creation.components.CreateOrEditTagContent

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateOrEditContentSheet(
    sheetType: CreateOrEditContentType,
    sheetState: SheetState,
    onDismissRequrest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    YabaModalSheet(
        modifier = modifier
            .fillMaxWidth()
            .fillMaxHeight(0.95f),
        sheetState = sheetState,
        onDismissRequest = onDismissRequrest,
        content = {
            when (sheetType) {
                CreateOrEditContentType.BOOKMARK -> {
                    CreateOrEditBookmarkContent(
                        modifier = Modifier.padding(16.dp),
                    )
                }

                CreateOrEditContentType.FOLDER -> {
                    CreateOrEditFolderContent(
                        modifier = Modifier.padding(16.dp),
                    )
                }

                CreateOrEditContentType.TAG -> {
                    CreateOrEditTagContent(
                        modifier = Modifier.padding(16.dp),
                    )
                }

                CreateOrEditContentType.NONE -> {
                    Box(modifier = Modifier)
                }
            }
        }
    )
}
