class OrganisationsController < ApplicationController
  def index
    @organisations = Organisation.all
  end


  def show
    @organisation = Organisation.find params[:id]
  end


  def new
    @organisation = Organisation.new
    @form = OrganisationForm.new @organisation
  end


  def create
    @organisation = Organisation.new
    @form = OrganisationForm.new @organisation
    if @form.validate(params[:organisation]) && @form.save
      redirect_to @form
    else
      render action: :new
    end
  end


  def edit
    @organisation = Organisation.find params[:id]
    @form = OrganisationForm.new @organisation
  end


  def update
    @organisation = Organisation.find params[:id]
    @form = OrganisationForm.new @organisation
    if @form.validate(params[:organisation]) && @form.save
      redirect_to @form
    else
      render action: :edit
    end
  end
end
