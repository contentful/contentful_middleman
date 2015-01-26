require 'fileutils'

module ContentfulMiddleman
  module Tools
    class NullBackup
      def restore; end
      def destroy; end
    end

    class Backup

      class << self
        def basepath
          ::File.join ENV["MM_ROOT"], ".tmp", "backups"
        end

        def ensure_backup_path!
          return if ::File.exists? basepath

          FileUtils.mkdir_p basepath
        end
      end


      def initialize(name, source)
        @name   = name
        @source = source

        self.class.ensure_backup_path!

        FileUtils.mkdir(path)
        FileUtils.mv(source, path)
      end


      def restore
        FileUtils.rm_rf(@source)
        FileUtils.mv(path, @source)
      end

      def destroy
        FileUtils.rm_rf(path)
      end

      private
      def path
        ::File.join self.class.basepath, name_and_date
      end

      def all_files_in_path(path)
        Dir.glob(::File.join(path, "*"))
      end

      def name_and_date
        @name_and_date ||= "#{@name}-#{Time.now.strftime("%Y%m%d%H%M%S")}"
      end

      module InstanceMethods
        def do_with_backup(backup_name, path_to_backup)
          backup        = create_backup backup_name,  path_to_backup
          remove_backup = false

          begin
            yield
            remove_backup = true
          rescue StandardError => e
            backup.restore
            remove_backup = true
            raise e
          ensure
            backup.destroy if remove_backup
          end
        end

        private
        def create_backup(backup_name, path_to_backup)
          if ::File.exist? path_to_backup
            Backup.new(backup_name, path_to_backup)
          else
            NullBackup.new
          end
        end
      end

    end
  end
end
