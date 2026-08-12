//
//  FeedXMLParser.swift
//  EaReader
//
//  Created by Eisuke Nomoto on 2026/08/10.
//

import Foundation

// XML解析処理
final class FeedXMLParser: NSObject, XMLParserDelegate {
    private var feed = ParsedFeed()
    private var elementStack: [String] = []
    private var currentText = ""
    private var isInsideItem = false

    private var itemTitle: String?
    private var itemLink: String?
    private var itemDateString: String?
    private var itemSummary: String?
    private var itemGUID: String?
    private var itemThumbnailURLString: String?

    private var channelTitleSet = false
    private var channelLinkSet = false
    private var channelDescriptionSet = false

    func parse(data: Data) -> ParsedFeed {
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = false
        parser.delegate = self
        parser.parse()
        return feed
    }

    private func localName(_ name: String) -> String {
        guard let colonRange = name.range(of: ":") else { return name }
        return String(name[colonRange.upperBound...])
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let name = localName(elementName)
        elementStack.append(name)
        currentText = ""

        if name == "item" || name == "entry" {
            isInsideItem = true
            itemTitle = nil
            itemLink = nil
            itemDateString = nil
            itemSummary = nil
            itemGUID = nil
            itemThumbnailURLString = nil
        }

        // Atom形式の<link>はテキストではなく href 属性を持つ自己終了タグ
        if name == "link", let href = attributeDict["href"] {
            let rel = attributeDict["rel"]
            guard rel == nil || rel == "alternate" else { return }
            if isInsideItem {
                if itemLink == nil { itemLink = href }
            } else if feed.link == nil {
                feed.link = URL(string: href)
            }
        }

        if isInsideItem, itemThumbnailURLString == nil {
            captureThumbnailIfPresent(elementName: name, attributes: attributeDict)
        }
    }

    // <media:thumbnail url="...">、<media:content medium="image" url="...">、
    // <enclosure url="..." type="image/*"> からサムネイル画像URLを検出する。
    // 名前空間プレフィックスは無視しているため、media:content はAtomの
    // プレーンな<content>(本文テキスト)と同じローカル名"content"になるが、
    // こちらは url 属性を持つ自己終了タグである点で区別できる。
    private func captureThumbnailIfPresent(elementName name: String, attributes: [String: String]) {
        switch name {
        case "thumbnail":
            if let urlString = attributes["url"] {
                itemThumbnailURLString = urlString
            }
        case "content":
            guard let urlString = attributes["url"] else { return }
            let medium = attributes["medium"]?.lowercased()
            let type = attributes["type"]?.lowercased()
            let looksLikeImage = medium == "image" || (type?.hasPrefix("image") ?? false)
            if looksLikeImage {
                itemThumbnailURLString = urlString
            }
        case "enclosure":
            guard let urlString = attributes["url"] else { return }
            let type = attributes["type"]?.lowercased()
            if type?.hasPrefix("image") ?? false {
                itemThumbnailURLString = urlString
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let name = localName(elementName)
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        currentText = ""

        if isInsideItem {
            handleItemEndElement(name: name, text: text)
        } else {
            handleChannelEndElement(name: name, text: text)
        }

        if !elementStack.isEmpty { elementStack.removeLast() }
    }

    private func handleItemEndElement(name: String, text: String) {
        switch name {
        case "title":
            if (itemTitle ?? "").isEmpty && !text.isEmpty { itemTitle = text }
        case "link":
            if itemLink == nil && !text.isEmpty { itemLink = text }
        case "pubDate", "date", "published", "updated", "issued":
            if itemDateString == nil && !text.isEmpty { itemDateString = text }
        case "description", "summary", "encoded", "content":
            if (itemSummary ?? "").isEmpty && !text.isEmpty { itemSummary = text }
        case "guid", "id":
            if itemGUID == nil && !text.isEmpty { itemGUID = text }
        case "item", "entry":
            finalizeCurrentItem()
        default:
            break
        }
    }

    private func finalizeCurrentItem() {
        defer { isInsideItem = false }

        let linkString = itemLink ?? (itemGUID?.hasPrefix("http") == true ? itemGUID : nil)
        let link = linkString.flatMap { URL(string: $0) }
        let identifier = itemGUID ?? itemLink ?? itemTitle ?? UUID().uuidString
        let title = TextSanitizer.cleanTitle(itemTitle ?? "(タイトルなし)")
        let summary = itemSummary.map { TextSanitizer.cleanSummary($0) }
        let now = Date()
        let item = Article(
            id: UUID(),
            feedId: 0,
            articleTitle: title,
            articleLink: link!,
            summary: summary,
            guid: link?.absoluteString ?? "",
            isRead: false,
            isFavorite: false,
            isHidden: false,
            thumbnailURL: itemThumbnailURLString.flatMap { URL.makeAbsolute($0) },
            publishedAt: itemDateString.flatMap { RSSDateParser.parse($0) },
            contentUpdatedAt: itemDateString.flatMap { RSSDateParser.parse($0) },
            fetchedAt: now,
            createdAt: now,
            updatedAt: now
        )
        feed.items.append(item)
    }

    private func handleChannelEndElement(name: String, text: String) {
        switch name {
        case "title":
            if !channelTitleSet && !text.isEmpty && elementStack.count <= 3 {
                feed.title = TextSanitizer.cleanTitle(text)
                channelTitleSet = true
            }
        case "link":
            if !channelLinkSet && !text.isEmpty {
                feed.link = URL(string: text)
                channelLinkSet = true
            }
        case "description", "subtitle", "tagline":
            if !channelDescriptionSet && !text.isEmpty && elementStack.count <= 3 {
                feed.description = TextSanitizer.cleanSummary(text)
                channelDescriptionSet = true
            }
        default:
            break
        }
    }
}
