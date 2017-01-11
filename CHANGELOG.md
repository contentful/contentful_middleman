# Change Log
## 1.5.0

### Added
* Added Contentful Client `default_locale` option as a configuration parameter
* Added possibility to set API URL for Preview Proxy

### Fixed
* Fix repeated items not appearing on reference arrays [#99](https://github.com/contentful/contentful_middleman/issues/99)
* Fix Default URL for Preview Proxy which is now the Preview API

## 1.4.2
### Fixed
* Fix localized resource serialization for localized Assets[#95](https://github.com/contentful/contentful_middleman/issues/95)

## 1.4.1
### Fixed
* Fix localized resource serialization[#95](https://github.com/contentful/contentful_middleman/issues/95)

## 1.4.0

### Added
* Add asset's `:description` to asset mapping[#82](https://github.com/contentful/contentful_middleman/pull/82)
* Add Page Size customization option when using `:all_entries`[#90](https://github.com/contentful/contentful_middleman/issues/90)

### Fixed
* Fixed error when asset's `:file` field is `nil`[#85](https://github.com/contentful/contentful_middleman/issues/85)

## 1.3.2
### Fixed
* Fixed Entry ID fetch on import task when having an ID field in the Content Type[#77](https://github.com/contentful/contentful_middleman/issues/77)
* Fixed `NoMethodError` when Entry has no populated fields[#76](https://github.com/contentful/contentful_middleman/issues/76)

## 1.3.1
### Fixed
* Middleman not loading extension due to `@app` reassignment

## 1.3.0 [YANKED]
### Added
* Added PreviewProxy for caching Preview API results
* Added `#with_preview` view helper for Preview API calls in real-time with a small cache
* Added `:webhook_controller` to extension options to be able to customize the Webhook Handler

### Changed
* Moved Webhook Integration to `before_server` hook to avoid multiple Webhook server instances running

## 1.2.0
### Added
* Include `:all_entries` option to `activate` block for getting over 1000 entries[#45](https://github.com/contentful-labs/contentful_middleman/issues/45)
* Update `middleman-core` required version
* Removes `middleman-blog` dependency[#9](https://github.com/contentful-labs/contentful_middleman/issues/9)
* Add Webhook Integration[#55](https://github.com/contentful-labs/contentful_middleman/pull/55)
* Clarify that `:all_entries` may need an `:order` attribute in the `:cda_query` for avoiding entry skipping and provided a sane default[#60](https://github.com/contentful/contentful_middleman/issues/60)
* Add Localize Helpers

## 1.1.1
### Changed
* Breadth-first search of linked entries

## 1.1.0
### Added
* New extension option: `use_preview_api`
* An example mapper that allows references from linked to linking entries

### Changed
* Make the all the entries available inside the mapper

### Fixed
* Calculate the version hash using the `updated_at` value of every entry instead of its revision

## 1.0.4
### Fixed
* Typo in the require statements
* The importing of entries with fields containing a list of elements other that links to entries now works
* Handle non included links i.e. when the `include` query parameter is not present or its value doesn't cover a link

## 1.0.3
## Fixed
* The importing of entries including `Contentful::Location` fields now works


## 1.0.2
### Fixed
* Include `middleman-blog` as dependency of the gem.

## 1.0.1
### Fixed
* Set local data file extension to *.yaml*

## 1.0.0
### Other
This release brings breaking changes that are not compatible with extension configurations in
previous versions. For more information about the supported configuration please read the
README file.

Changes in this release:

* Support multiple activations of the extension. Import from multiple spaces
* Decouple mapping of entries from blog post layout. Support custom mappers
* Store imported entries as local data
* Optionally rebuild static site only when there are changes in the imported data

## 0.0.4
### Other
* Publish first Gem version

## 0.0.3

### Other
* Minor updates


## 0.0.2
### Other
* First release
