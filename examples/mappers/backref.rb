# A function that returns a Mapper class for adding back-references to
# contentful data files.  If a Product content type had a "company" entry field
# that referenced a Company content type, using the following BackrefMapper on
# the Company content type would add a "products" field to the company data
# files with a list of all Products that reference that Company:
#
# BackrefMapper(EMPLOYEE_CONTENT_TYPE_ID, 'department', 'employees')
#
# For example, given these two files:
#
# ---
# :id: 12345
# :name: Jet-Propelled Tennis Shoes
# :company:
# - :id: 54321
#   :name: Acme
#
# ---
# :id: 54321
# :name: Acme
# :website: http://acme.example.com/
#
# The Acme company YAML file would become:
#
# ---
# :id: 54321
# :name: Acme
# :website: http://acme.example.com/
# :products:
# - :id: 12345
#   :name: Jet-Propelled Tennis Shoes
#   :company:
#   - :id: 54321
#     :name: Acme
#
# Params:
# +content_type_id+:: The ID of the content_type that references the
# content_type that this mapper is being applied to
# +content_type_field+:: The field name on the content_type to look for
# references
# +backref_field+:: The new field to create to hold the list of references
def self.BackrefMapper(content_type_id, content_type_field, backref_field)
  klass = Class.new ContentfulMiddleman::Mapper::Base do

    @@content_type_id = content_type_id
    @@content_type_field = content_type_field
    @@backref_field = backref_field

    def map(context, entry)
      super
      content_type_entries = @entries.select { |e| e.sys[:contentType].id == @@content_type_id }
      referencing_entries = content_type_entries.select{ |e| e.send(@@content_type_field).map{|x| x.id}.include? entry.id }
      referencing_ids = referencing_entries.map{ |e| e.id }
      context.set(@@backref_field, map_value(referencing_ids))
    end
  end

  return klass
end
