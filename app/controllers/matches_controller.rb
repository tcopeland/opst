class MatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_match, only: [:show, :edit, :update, :destroy]

  def index
    load_matches_and_season
  end

  def show
  end

  def new
    @match = current_user.matches.build
    @maps = Map.all.map { |map| [map.name, map.id] }
    @heroes = Hero.all.map { |hero| [hero.name, hero.id] }
  end

  def edit
    @maps = Map.all.map { |map| [map.name, map.id] }
    @heroes = Hero.all.map { |hero| [hero.name, hero.id] }
  end

  def create
    number = current_user.matches.last.number + 1
    @match = current_user.matches.build(
      skill_rating: match_params[:skill_rating], number: number
    )
    @match.update_associations(match_params[:hero_ids], params[:map_id])

    if @match.save
      @match.update_skill_rating_diff
      @match.calculate_result unless Match.first_in_season?
      @match.update_streak
      @match.save

      load_matches_and_season
      load_and_render_index
    else
      render :new
    end
  end

  def update
    @match.attributes = match_params
    @match.update_associations(match_params[:hero_ids], params[:map_id])
    @match.update_streak

    if @match.save
      @match.update_skill_rating_diff
      @match.calculate_result unless Match.first_in_season?
      @match.save

      load_matches_and_season
      load_and_render_index
    else
      render :edit
    end
  end

  def destroy
    @match.destroy
    load_matches_and_season
    load_and_render_index
  end

  private

  def set_match
    @match = current_user.matches.find(params[:id])
  end

  def match_params
    params.require(:match).permit(:map_ids, :skill_rating, :result, hero_ids: [])
  end

  def load_matches_and_season
    @matches = current_user.matches
                .current_season
                .includes(:map, :destination)
                .order(created_at: :desc)
                .paginate(page: params[:page], per_page: 20)
    @season = Season.last
    @first_match_sr = current_user.matches.current_season.first.skill_rating
  end

  def load_and_render_index
    render :index, change: 'matches'
  end
end
