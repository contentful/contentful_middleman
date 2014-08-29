module ContentfulMiddleman
  class VersionHash
    class << self
      def source_root=(source_root)
        @source_root = source_root
      end

      def read_for_space(space_name)
        hashfilename_for_space = hashfilename(space_name)
        ::File.read(hashfilename_for_space) if File.exist? hashfilename_for_space
      end

      def write_for_space_with_entries(space_name, entries)
        sorted_entries           = entries.sort {|a, b| a.id <=> b.id}
        ids_and_revisions_string = sorted_entries.map {|e| "#{e.id}#{e.revision}"}.join
        entries_hash             = Digest::SHA1.hexdigest( ids_and_revisions_string )

        File.open(hashfilename(space_name), 'w') { |file| file.write(entries_hash) }

        entries_hash
      end

      private
        def hashfilename(space_name)
          ::File.join(@source_root, ".#{space_name}-space-hash")
        end
    end
  end
end
