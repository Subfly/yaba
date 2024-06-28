package core.settings.localization.assets.localization

class TurkishLocalization : YabaLocalization() {
    override val APP_NAME: String
        get() = "Yaba"
    override val OTHERS_FOLDER_NAME: String
        get() = "Diğerleri"
    override val FOLDERS_TITLE: String
        get() = "Dosyalar"
    override val TAGS_TITLE: String
        get() = "Etiketler"
    override val SYNC: String
        get() = "Eşitle"
    override val SETTINGS: String
        get() = "Ayarlar"
    override val CREATE_BOOKMARK: String
        get() = "Kayıt Oluştur"
    override val CREATE_FOLDER: String
        get() = "Dosya Oluştur"
    override val CREATE_TAG: String
        get() = "Etiket Oluştur"
    override val ADD_TAG: String
        get() = "Etiket Ekle"
    override val EDIT_BOOKMARK: String
        get() = "Kaydı Düzenle"
    override val EDIT_FOLDER: String
        get() = "Dosyayı Düzenle"
    override val EDIT_TAG: String
        get() = "Etiketi Düzenle"
    override val PREVIEW: String
        get() = "Ön İzleme"
    override val WRITE_HERE: String
        get() = "Buraya yazınız..."
    override val TAG_NAME: String
        get() = "Etiket İsmi"
    override val FOLDER_NAME: String
        get() = "Doysa Adı"
    override val COLOR_SELECTION: String
        get() = "Renk Seçimi"
    override val COLOR_SELECTION_FIRST: String
        get() = "İlk Etiket Rengi"
    override val COLOR_SELECTION_SECOND: String
        get() = "İkinci Etiket Rengi"
    override val ICON_SELECTION: String
        get() = "İkon Seçimi"
    override val SEARCH_FIELD_PLACEHOLDER: String
        get() = "Aramaya başlamak için yazın..."
    override val BOOKMARK_COUNT_PREFIX_TEXT: String
        get() = "Kayıt Sayısı: "
    override val SEARCH_FOR_ICON_TEXT: String
        get() = "İkon Arayın"
    override val THEME_AND_LANGUAGE_OPTIONS: String
        get() = "Tema ve Dil Seçenekleri"
    override val CONTENT_OPTIONS: String
        get() = "İçerik Ayarları"
    override val THEME_SELECTION_OPTION: String
        get() = "Tema Seçimi"
    override val THEME_SELECTION_OPTION_SYSTEM: String
        get() = "Sistemi Takip Et"
    override val THEME_SELECTION_OPTION_DARK: String
        get() = "Karanlık Tema"
    override val THEME_SELECTION_OPTION_LIGHT: String
        get() = "Aydınlık Tema"
    override val LANGUAGE_SELECTION_OPTION: String
        get() = "Dil Seçimi"
    override val LANGUAGE_SELECTION_EN: String
        get() = "İngilizce"
    override val LANGUAGE_SELECTION_TR: String
        get() = "Türkçe"
    override val CONTENT_VIEW_SELECTION_OPTION: String
        get() = "İçerik Görünümü"
    override val CONTENT_VIEW_SELECTION_GRID: String
        get() = "Izgara"
    override val CONTENT_VIEW_SELECTION_LIST: String
        get() = "Liste"
    override val SETTINGS_PRIVATE_CONTENT_PASSWORD_TITLE: String
        get() = "Gizli İçerik Şifresi"
    override val NO_CONTENT_HOME_LABEL: String
        get() = "Burası Boş"
    override val NO_CONTENT_HOME_MESSAGE: String
        get() = "Hemen 'Ekle' butonunu kullanarak ilk kaydını oluşturabilirsin"
    override val NO_FOLDERS_HOME_LABEL: String
        get() = "Hiç Dosya Yok"
    override val NO_FOLDERS_HOME_MESSAGE: String
        get() = "Hemen 'Ekle' butonunu kullanarak ilk dosyanı oluşturabilirsin"
    override val NO_TAGS_HOME_LABEL: String
        get() = "Hiç Etiket Yok"
    override val NO_TAGS_HOME_MESSAGE: String
        get() = "Hemen 'Ekle' butonunu kullanarak ilk etiketini oluşturabilirsin"
    override val NO_FOLDERS_SELECT_FOLDER_LABEL: String
        get() = "Hiç Dosya Yok"
    override val NO_FOLDERS_SELECT_FOLDER_MESSAGE: String
        get() = "Hemen Ana Menü'deki 'Ekle' butonunu kullanarak ilk dosyanı oluşturabilirsin"
    override val NO_TAGS_SELECT_TAGS_LABEL: String
        get() = "Hiç Etiket Yok"
    override val NO_TAGS_SELECT_TAGS_MESSAGE: String
        get() =  "Hemen Ana Menü'deki 'Ekle' butonunu kullanarak ilk etiketini oluşturabilirsin"
    override val NO_TAGS_SELECTED_SELECT_TAGS_LABEL: String
        get() = "Hiç Etiket Seçilmedi"
    override val NO_TAGS_SELECTED_CLICK_HERE_SELECT_TAGS_LABEL: String
        get() = "Buraya tıklayarak seçim yapabilirsin"
    override val NO_TAGS_SELECTED_SELECT_TAGS_MESSAGE: String
        get() = "Aşağıdaki etiketlere basarak etiket seçebilirsin"
    override val NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_LABEL: String
        get() = "Seçilebilecek Etiket Kalmadı"
    override val NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_MESSAGE: String
        get() = "Tüm etiketleri seçtin, hepsine ihtiyacın olduğuna emin misin?"
    override val NO_BOOKMARKS_CARD_MESSAGE: String
        get() = "Hiç Kaydı Yok"
    override val EDIT_TITLE: String
        get() = "Düzenle"
    override val DELETE_TITLE: String
        get() = "Sil"
    override val SELECTED_TAGS_TITLE: String
        get() = "Seçili Etiketler"
    override val SELECTABLE_TAGS_TITLE: String
        get() = "Seçilebilir Etiketler"
    override val FINISH_TAG_SELECTION: String
        get() = "Etiket Seçimini Tamamla"

    override fun NO_FOLDERS_SELECT_FOLDER_FORMATTABLE_MESSAGE(query: String): String {
        return "'$query' isimli bir dosya bulunamadı"
    }

    override fun NO_SELECTABLE_TAGS_AVAILABLE_SELECT_TAGS_FORMATTABLE_MESSAGE(
        query: String,
    ): String {
        return "'$query' isimli bir etiket bulunamadı"
    }
}
