class DictionaryController < ApplicationController

  layout "ref"
  
  in_place_edit_for :concept, :name
  in_place_edit_for :concept, :description
  
  def concepts_for_lookup
    @concepts = Concept.find(:all)
    @headers['content-type'] = 'text/javascript'
    render :layout => false
  end
  
  def test
  end
 
  def show_concept
    if params[:id].nil?
      @concept = Concept.new
      @concept.name = "Edit_me"
      @concept.description = "Me too"
      @concept.save!
    else
      @concept = Concept.find(params[:id])
    end
  end

  def list_concepts
    @concepts = Concept.find(:all)
  end
  
  def add_answer
    @concept = Concept.find(params[:id])
    @concept_answer = Concept.find(:first, :conditions => ['name = ?', params[:concept_lookup]])
    @answer = Answer.new(:concept_id => @concept.id, :answer_id => @concept_answer.id)
    @answer.save!
    
    render :partial => "answer", :object => @answer, :layout => false
  end
end
