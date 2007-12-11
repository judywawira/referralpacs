class PatientController < ApplicationController
  layout "ref"
  before_filter :authorize_login # Make sure an authorized user is logged in.
  before_filter :security, :except => :find

  protected
  def security
    # This method is called before any method that
    # Modifies patient data
    current_user = User.find(session[:user_id])
    
    unless current_user.privilege.modify_patient
      flash[:notice] = "Not enough privilege to modify patients."
      return(redirect_to :action => "find")
    end
    
  end

  public
  def find
    # If the request is a get, there is nothing to do.
  
    # We'll use this in this method, and also in the view to make
    # sure the links are correct
    @current_user = User.find(session[:user_id])  
  
    if request.post?
        
      # AMPATH mrn is the best identifier, so let's see if we have one of those first
      unless params[:patient][:mrn_ampath] == ""
        
        # TODO: Will need to rectify patients who are already in the database
        # Who haven't had their AMPATH identities verified
        # Perhaps we should add a field to the patient database that
        # Indicates that the demographics for that patient have been checked
        
        @patients = Patient.find(:all,
                    :conditions => ['mrn_ampath = ?', params[:patient][:mrn_ampath]])
                    
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
          else
            @encounters = Encounter.find(:all, :conditions => ['date LIKE ?', '%' + params[:encounter][:date] + '%'])
            @patients = []
            @encounters.each { |enc| @patients << enc.patient }       
            @patients.uniq!
          end
        end
      end


      # Our patients arrays should be set now.  If not, no one was found.
      
      if @patients.nil? || @patients.empty?
         render :update do |page|

           #TODO Shouldn't this be in an RJS template?

           # Can the current user add patients?  If so, let's give them the opportunity.
           unless @current_user.privilege.add_patient
             page.replace_html "patient-list", "No patients found, please search again"
           else
             page.replace_html "patient-list", "No patients found. <br/><br/>" + link_to("New Patient", :controller => :patient, :action => :new)
           end
           
           page.visual_effect :highlight, "patient-list"
           
           page.form.reset 'patient-form'
           
         end
       else
         
         render :partial => "ajax_list_patients"
         
      end
    end
  end
  
  def new
    @all_tribes = Tribe.find(:all, :order => "name ASC")
    if request.get?
      @patient = Patient.new()
    else
      @patient = Patient.new(params[:patient])
      if @patient.save
        flash[:notice] = 'Patient was successfully created.'
        redirect_to :controller => :encounter, :action => "find", :id => @patient.id
      else
        render :action => 'new'
      end
    end
  end
  
  def edit
    @all_tribes = Tribe.find(:all, :order => "name ASC")
    if request.get?
      @patient = Patient.find(params[:id])
    else
      @patient = Patient.find(params[:id])
      if @patient.update_attributes(params[:patient])
          flash[:notice] = "Saved #{@patient.full_name}"
      else
          flash[:notice] = "Error saving patient."
      end
      redirect_to :action => "find"
    end
  end
  
  def delete
    # It takes not only modify_patient, but also remove_patient privilege to delete
    
    current_user = User.find(session[:user_id])
    patient = Patient.find(params[:id])
    
    if current_user.privilege.remove_patient
      patient.destroy
    else
      flash[:notice] = "Not enough privilege to delete a patient"

    end
    redirect_to :action => "find"    
  end


end
