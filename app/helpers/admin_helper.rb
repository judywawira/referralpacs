module AdminHelper

  def setup_admin_layout
    
    set_current_user_banner

    @command_list = [
        link_to('Statistics', :action => :statistics),
        link_to('Manage Users', :action => :list_users),
        link_to('Manage Providers', :action => :list_providers),
        link_to('Manage Clients', :action => :list_clients),
        link_to('Find Patients', :action => :find_patients),
        link_to('New Patient', :action => :new_patient)]
  
    unless @patient.nil? || @patient.new_record?
      set_current_patient_banner
      @command_list << link_to("#{@patient.full_name}", :action => :find_encounters, :id => @patient)
    end

  end

end
