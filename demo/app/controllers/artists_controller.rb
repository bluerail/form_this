class ArtistsController < ActionController::Base
  protect_from_forgery with: :exception

  def index
    @artists = Artist.all
  end


  def show
    @artist = Artist.find params[:id]
  end


  def new
    @artist = Artist.new
    @form = ArtistForm.new @artist
  end


  def add_album
    @artist = Artist.find params[:id]
    @form = ArtistAddAlbumForm.new @artist
  end


  def create
    @artist = Artist.new
    @form = ArtistForm.new @artist
    if @form.validate(params[:artist]) && @form.save
      redirect_to @form
    else
      render action: :new
    end
  end


  def edit
    @artist = Artist.find params[:id]
    @form = ArtistForm.new @artist
  end


  def update
    @artist = Artist.find params[:id]
    @form = ArtistForm.new @artist
    if @form.validate(params[:artist]) && @form.save
      redirect_to @form
    else
      render action: :edit
    end
  end
end
