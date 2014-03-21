require "middleman-core"

require 'contentful_middleman/version'
require 'contentful_middleman/core'
require "contentful_middleman/commands/sync_blog"

::Middleman::Extensions.register(:contentful, ContentfulMiddleman::Core)
