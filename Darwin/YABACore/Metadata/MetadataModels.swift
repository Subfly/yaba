//
//  MetadataModels.swift
//  YABACore
//
//  Native metadata extraction result models (non-WebView bridge types).
//

import Foundation

public struct LinkMetadataResult: Sendable, Equatable {
    public var cleanedUrl: String
    public var title: String?
    public var description: String?
    public var author: String?
    public var date: String?
    public var audio: String?
    public var video: String?
    public var image: String?
    public var logo: String?

    public init(
        cleanedUrl: String,
        title: String? = nil,
        description: String? = nil,
        author: String? = nil,
        date: String? = nil,
        audio: String? = nil,
        video: String? = nil,
        image: String? = nil,
        logo: String? = nil
    ) {
        self.cleanedUrl = cleanedUrl
        self.title = title
        self.description = description
        self.author = author
        self.date = date
        self.audio = audio
        self.video = video
        self.image = image
        self.logo = logo
    }
}
