# Change Log

## Upcoming
## Fixed
* The importing of entries including `Contentful::Location` fields now works
* The importing of entries with fields containing a list of elements other that links to entries now works
* Handle non included links i.e. when the `include` query parameter is not present or its value doesn't cover a link

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
