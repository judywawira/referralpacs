# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 6) do

  create_table "encounter_types", :force => true do |t|
    t.column "name",        :string
    t.column "modality",    :string
    t.column "created_at",  :datetime
    t.column "created_by",  :integer
    t.column "modified_at", :datetime
    t.column "modified_by", :datetime
  end

  create_table "encounters", :force => true do |t|
    t.column "date",       :datetime
    t.column "patient_id", :integer
    t.column "indication", :string
    t.column "findings",   :string
    t.column "impression", :string
    t.column "created_by", :integer
    t.column "created_at", :datetime
    t.column "updated_by", :integer
    t.column "updated_at", :datetime
  end

  create_table "patients", :force => true do |t|
    t.column "mrn_ampath",          :integer
    t.column "national_identifier", :integer
    t.column "prefix",              :string
    t.column "given_name",          :string
    t.column "middle_name",         :string
    t.column "family_name",         :string
    t.column "last_name_prefix",    :string
    t.column "gender",              :string
    t.column "race",                :string
    t.column "tribe",               :integer
    t.column "address1",            :string
    t.column "address2",            :string
    t.column "created_by",          :integer
    t.column "created_at",          :datetime
    t.column "updated_by",          :integer
    t.column "updated_at",          :datetime
    t.column "birthdate",           :datetime
    t.column "mtrh_rad_id",         :integer
  end

  create_table "users", :force => true do |t|
    t.column "name",            :string
    t.column "hashed_password", :string
    t.column "email",           :string
    t.column "access_level_id", :integer
    t.column "provider_id",     :integer
    t.column "created_by",      :integer
    t.column "created_at",      :datetime
    t.column "updated_by",      :integer
    t.column "updated_at",      :datetime
  end

end
