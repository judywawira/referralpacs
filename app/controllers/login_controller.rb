class LoginController < ApplicationController

  before_filter :authorize_login, :except => "login"
  layout "admin"
  
  # If the requst is of the GET type, return the add_user
  # form.  Otherwise, we have a POST request, attempt to add the
  # new user and return to the user list.
  
  def index
    redirect_to(:action => "login")
  end
  
  def add_user
    authorize_add_user
    
    @all_privileges = Privilege.find(:all)
    if request.get?
      @user = User.new
    else 
      @user = User.new(params[:user])
      if @user.save
        flash[:notice] = "User #{@user.email} created."
        redirect_to(:action => "list_users")
      end
    end
  end

  # Delete the user with the given ID from the database.
  # The model raises an exception if we attempt to delete
  # the special user.
  def delete_user
  
    # Check to see if the current user is authorized to remove users.
    authorize_remove_user

    id = params[:id]
    if id == session[:user_id]
      flash[:notice] = "Can't delete self"
    else
      if id && user = User.find(id)
        begin
          user.destroy
          flash[:notice] = "User #{user.name} deleted"
        rescue
          flash[:notice] = "Can't delete that user"
        end
      end
    end
    redirect_to(:action => :list_users)
  end

  def list_users
    @all_users = User.find(:all)
  end
  
  def edit_user
    id = params[:id]
    @user = User.find(id)
    @all_privileges = Privilege.find_all
  end
  
  def update_user
    id = params[:id]
    @user = User.find(id)
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'list_users'
    else
      render :action => 'edit_user'
    end
  
  end
  
  def login
    if request.get?
      session[:user_id] = nil
      @user = User.new
    else
      @user = User.new(params[:user])
      logged_in_user = @user.try_to_login
      if logged_in_user
        session[:user_id] = logged_in_user.id
        redirect_to(:action => "list_users")
      else
        flash[:notice] = "Invalid user/password combination"
      end
    end
  end

  def logout
    session[:user_id] = nil
    redirect_to(:action => "login")
  end
  
  def add_provider
    if request.get?
      @provider = Provider.new
      @all_privileges = Privilege.find :all
    else
      @provider = Provider.new(params[:user])
      if @provider.save
        flash[:notice] = "Provider #{@provider.email} created."
        redirect_to(:action => "list_users")
      end  
    end
  end
  
  private
  def authorize_add_user
    @user = User.find session[:user_id]
    unless @user.privilege.add_user?
      flash[:notice] = "Not authorized to add users"
      redirect_to(:controller => "login", :action => "list_users")
    end
  end
  
  private
  def authorize_remove_user
    @user = User.find session[:user_id]
    unless @user.privilege.remove_user?
      flash[:notice] = "Not authorized to remove users"
      redirect_to(:controller => "login", :action => "list_users")
    end
  end
  
end
