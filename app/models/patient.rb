class Patient < ActiveRecord::Base
  has_many :encounters
  belongs_to :tribe
  
  validates_presence_of :given_name, :family_name
  validates_uniqueness_of :mtrh_rad_id, :allow_blank => true                          
  validates_uniqueness_of :mrn_ampath, :allow_blank => true
  
  before_save :uppercase
  
  require "net/https"
  
  #Provide a concatenated name for cleaner display.
  def full_name
    unless self.given_name.nil? || self.family_name.nil?
      self.given_name + " " + self.family_name
    end
  end
  
  def birthdate_formatted
    self.birthdate.strftime("%d %b %Y") unless birthdate.nil?
  end
  
  def uppercase
    write_attribute :family_name, family_name.upcase
    write_attribute :middle_name, middle_name.upcase unless middle_name.nil?
    write_attribute :given_name, given_name.upcase
  end
  
  def Patient.search(params)
    
    # AMPATH mrn is the best identifier, so let's see if we have one of those first
    unless params[:patient][:mrn_ampath] == ""
            
      # We were given an openmrs identifier, so we have a few taskss
      # 1. Search locally to see if we already know this patient
      #    - If so, make sure they have been verified against openmrs
      # 2. If we don't already know this patient, we need to get the patient's demographics
      #    from openmrs.
      
      local_patient = Patient.find(:first, :conditions => ['mrn_ampath = ?', params[:patient][:mrn_ampath]])
      
      
      if local_patient.nil?
        # This is the case where we didn't find the patient locally.
        # So, we'll see if the openMRS server knows about this patient if we're integrated
        
        if $openmrs == true
          @patients = find_openmrs_patient(params[:patient][:mrn_ampath])
        end

      else
        # We found the patient locally, now we can simply return the patient
        # As long as they have been verified.
        unless local_patient.openmrs_verified
          @patients = local_patient          
        else
          # TODO verifiation process will go here
          @patients = local_patient
        end
      end
      
    else
      # If we don't have an AMPATH ID, what about a MTRH radiology id?

      unless params[:patient][:mtrh_rad_id] == ""
        @patients = Patient.find(:all, 
                    :conditions => ['mtrh_rad_id = ?', params[:patient][:mtrh_rad_id]])
      else
        # We're left to search names or filter encounters by date to get patient names
        unless params[:patient][:name] == ""
          @patients = Patient.find(:all, 
                      :conditions => ['LOWER(CONCAT(given_name, " ", family_name)) LIKE ?', '%' + params[:patient][:name].downcase + '%'])
        end
      end
    end
    
    return @patients
    
  end
  
  def Patient.find_openmrs_patient(mrn_openmrs)
    # This method communicates with the OpenMRS REST interface on the server
    # uses REXML to process the response.
    # All of the globals below are set in config/openmrs.conf.rb
    
    # This came from a browser, so let's sanitize it
    mrn_openmrs = CGI.escape(mrn_openmrs)
    
    url = "https://#{$openmrs_server}/openmrs/moduleServlet/restmodule/api/patient/#{mrn_openmrs}"
    
    # Create a URI object from our url string.
    url = URI.parse(url)

    # Create a request object from our url and attach the authorization data.
    req = Net::HTTP::Get.new(url.path)
    req.basic_auth($openmrs_user, $openmrs_password)
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    result = http.request(req)
    case result
      when Net::HTTPSuccess
        doc = REXML::Document.new(result.read_body)
        @patients = Patient.save_xml_to_patient_object(doc) unless doc.elements["//identifier"].nil?
      else
        #TODO insert error stating OpenMRS connection is down.
        #res.error!
    end    
  end
  
  def Patient.save_xml_to_patient_object(doc)
    # This method takes a REXML document and returns a patient object.
    
    new_patient = Patient.new()
    new_patient.mrn_ampath = doc.elements["//identifier"].text unless doc.elements["//identifier"].nil?
    new_patient.given_name = doc.elements["//givenName"].text unless doc.elements["//givenName"].nil?
    new_patient.middle_name = doc.elements["//middleName"].text unless doc.elements["//middleName"].nil?
    new_patient.family_name = doc.elements["//familyName"].text unless doc.elements["//familyName"].nil?
    new_patient.birthdate = DateTime.parse(doc.elements["//@birthdate"].to_s) unless doc.elements["//@birthdate"].nil?
    new_patient.birthdate_estimated = doc.elements["//@birthdateEstimated"] unless doc.elements["//@birthdateEstimated"].nil?
    new_patient.address1 = doc.elements["//address1"].text unless doc.elements["//address1"].nil?
    new_patient.address2 = doc.elements["//address2"].text unless doc.elements["//address2"].nil?
    new_patient.city_village = doc.elements["//cityVillage"].text unless doc.elements["//cityVillage"].nil?
    new_patient.state_province = doc.elements["//stateProvince"].text unless doc.elements["//stateProvince"].nil?
    new_patient.country = doc.elements["//country"].text unless doc.elements["//country"].nil?
    new_patient.mtrh_rad_id = nil
    new_patient.openmrs_verified = true
    new_patient.save!
    
    return new_patient
    
  end

end
