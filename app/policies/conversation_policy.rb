class ConversationPolicy < ApplicationPolicy
  def index?  = true
  def show?   = record.user == user
  def create? = true

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user:)
    end
  end
end
