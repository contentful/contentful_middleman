module ContentfulMiddleman
  module LocalData
    class Store
      include ContentfulMiddleman::Tools::Backup::InstanceMethods

      class << self
        def base_path=(path)
          @base_path = path
        end

        def base_path
          @base_path
        end
      end

      def initialize(files, folder)
        @files  = files
        @folder = folder
      end

      def write
        do_with_backup backup_name, path_to_backup do
          @files.each(&:write)
        end
      end

      private
      def backup_name
        "#{@folder}-data-backup"
      end

      def path_to_backup
        ::File.join(self.class.base_path, @folder)
      end
    end
  end
end
