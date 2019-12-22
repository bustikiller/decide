class VotingsController < ApplicationController
  load_and_authorize_resource

  # GET /votings
  def index
    @votings = Voting.all

    respond_to do |format|
      format.html
      format.json { render json: @votings, adapter: :json }
    end
  end

  # GET /votings/1
  def show
    respond_to do |format|
      format.html
      format.json { render json: @voting }
    end
  end

  # GET /votings/new
  def new
    @voting = Voting.new
  end

  # GET /votings/1/edit
  def edit
  end

  # POST /votings
  def create
    @voting = Voting.new(voting_params)

    if @voting.save
      redirect_to @voting, notice: 'Voting was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /votings/1
  def update
    if @voting.update(voting_params)
      redirect_to @voting, notice: 'Voting was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /votings/1
  def destroy
    @voting.destroy
    redirect_to votings_url, notice: 'Voting was successfully destroyed.'
  end

  private
    # Only allow a trusted parameter "white list" through.
    def voting_params
      params.require(:voting).permit(:title, :description, :status)
    end
end
