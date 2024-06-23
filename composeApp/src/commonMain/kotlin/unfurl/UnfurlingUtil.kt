package unfurl

import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.HttpRequestRetry
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.logging.DEFAULT
import io.ktor.client.plugins.logging.LogLevel
import io.ktor.client.plugins.logging.Logger
import io.ktor.client.plugins.logging.Logging
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import kotlinx.datetime.LocalDateTime
import unfurl.models.TwitterCardType
import unfurl.models.UnfurlMetaModel
import unfurl.models.UnfurlModel
import unfurl.models.UnfurlOEmbedModel
import unfurl.models.UnfurlTwitterModel

object UnfurlingUtil {
    private val tagsToExtract = listOf(
        "og:url",
        "og:title",
        "og:description",
        "og:site_name",
        "og:image",
        "og:image:width",
        "og:image:height",
        "og:image:secure_url",
        "article:publisher",
        "article:author",
        "article:published_time",
        "twitter:card",
        "twitter:site",
        "twitter:creator",
        "twitter:title",
        "twitter:description",
        "twitter:image",
        "twitter:label1",
        "twitter:data1",
        "twitter:label2",
        "twitter:data2",
        "author"
    )

    private val client: HttpClient by lazy {
        HttpClient(CIO) {
            install(HttpTimeout) {
                requestTimeoutMillis = 10000L
                connectTimeoutMillis = 10000L
            }
            install(HttpRequestRetry) {
                retryOnExceptionOrServerErrors(maxRetries = 3)
                exponentialDelay()
                modifyRequest { request ->
                    request.headers.append(
                        name = "x-retry-count",
                        value = retryCount.toString(),
                    )
                }
            }
            install(Logging) {
                logger = Logger.DEFAULT
                level = LogLevel.ALL
            }
        }
    }

    suspend fun getUnfurledMetadata(url: String): UnfurlModel {
        try {
            val response = client.get(urlString = url).bodyAsText()
            return extractMetaTags(httpString = response)
        } catch (e: Exception) {
            return UnfurlModel.Error
        }
    }

    private fun extractMetaTags(httpString: String): UnfurlModel {
        val metaTags = mutableMapOf<String, String>()

        // Extract <title> tag
        val titleRegex = Regex("<title>(.*?)</title>", RegexOption.IGNORE_CASE)
        val titleMatch = titleRegex.find(httpString)
        if (titleMatch != null) {
            metaTags["title"] = titleMatch.groupValues[1].trim()
        }

        // Regex pattern to match meta tags with property or name attribute
        val metaTagPattern =
            """<meta\s+(?:property|name)="(${
                tagsToExtract.joinToString(separator = "|")
            })"\s+content="([^"]*)"\s*/?>"""
                .toRegex(RegexOption.IGNORE_CASE)

        // Find all matches and extract the required meta tags
        val matches = metaTagPattern.findAll(httpString)
        for (match in matches) {
            val tag = match.groupValues[1].trim()
            val content = match.groupValues[2].trim()
            if (tag in tagsToExtract) {
                metaTags[tag] = content
            }
        }

        return mapToUnfurlModel(metaTags)
    }

    private fun mapToUnfurlModel(metaTags: Map<String, String>): UnfurlModel {
        val oEmbedModel = UnfurlOEmbedModel(
            url = metaTags["og:url"],
            title = metaTags["og:title"],
            description = metaTags["og:description"],
            siteName = metaTags["og:site_name"],
            imageUrl = metaTags["og:image"],
            imageSecureUrl = metaTags["og:image:secure_url"],
            width = metaTags["og:image:width"]?.toFloatOrNull(),
            height = metaTags["og:image:height"]?.toFloatOrNull(),
        )

        val twitterModel = UnfurlTwitterModel(
            card = metaTags["twitter:card"]?.let {
                TwitterCardType.valueOf(it.uppercase())
            },
            site = metaTags["twitter:site"],
            creator = metaTags["twitter:creator"],
            title = metaTags["twitter:title"],
            description = metaTags["twitter:description"],
            imageUrl = metaTags["twitter:image"],
            extraDataOne = Pair(
                first = metaTags["twitter:label1"],
                second = metaTags["twitter:data1"],
            ),
            extraDataTwo = Pair(
                first = metaTags["twitter:label2"],
                second = metaTags["twitter:data2"],
            ),
        )

        val metaModel = UnfurlMetaModel(
            publisher = metaTags["article:publisher"],
            author = metaTags["article:author"],
            publishedTime = metaTags["article:published_time"]?.let {
                LocalDateTime.parse(it)
            },
        )

        return UnfurlModel.Success(
            oEmbedModel = oEmbedModel,
            twitterModel = twitterModel,
            metaModel = metaModel,
            author = metaTags["author"],
        )
    }
}
