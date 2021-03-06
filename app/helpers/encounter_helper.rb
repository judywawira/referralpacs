module EncounterHelper
  
  def encounter_links_helper(encounter)
    # Make sure that we get the appropriate links based on the current user
    @links = [] 
    
    # Only users who can modify encounters should see the details and delete links
    if @current_user.privilege.modify_encounter
      if encounter.status != "final"
        if @current_user.privilege.name  == "radiologist" || @current_user.privilege.name == "admin" || @current_user.privilege.name == "super_radiologist"
          @links << link_to('Create Report', :action => 'report', :id => encounter.id)
        end
        
        if @current_user.privilege.name == "assistant"
          @links << link_to('Triage', :action => 'triage', :id => encounter.id)
        end
      
        @links << link_to('Edit Details', :action => 'details', :id => encounter.id)
      end
      
      # Only show the print link if there is an available report
      if encounter.status == "final" || encounter.status == "ready_for_printing"
        @links << link_to('Print Report', :action => 'pdf_report', :id => encounter.id, :format => :pdf)
      end

      @links << link_to('Delete', 
                         {:action => 'delete', :id => encounter.id}, 
                          :confirm => 'This cannot be undone, are you sure?')
    end

  end
  
  #These are the helpers that create the report form.
  
  def radio_tag_helper(value_concept, answer_concept)
    if answer_concept == "none" || answer_concept == "normal"
      test = !@tag_hash.has_key?(value_concept)
    else
      test = @tag_hash[value_concept] == answer_concept
    end
    return "<label>" + radio_button_tag(value_concept, answer_concept, test) + answer_concept.humanize + "</label>"      
  end
  
  def fieldset_helper(question, choices)
    return_string = ""
    
    choices.each do |choice|
      return_string += radio_tag_helper(question, choice) + "\n"
    end
    
    return return_string
  end
  
  def checkbox_helper(question, choices)
    return_string = ""
    
    choices.each do |choice|
      return_string += "<label>" + check_box_tag(question + "+" + choice, true, @tag_hash[question][choice]) + choice.humanize + "</label>" + "\n"
    end
    return return_string
  end
  
end
