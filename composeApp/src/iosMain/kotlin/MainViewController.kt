import androidx.compose.ui.window.ComposeUIViewController
import di.DIHelper

fun MainViewController() = ComposeUIViewController(
    configure = { DIHelper.initKoin() }
) {
    YabaApp()
}
