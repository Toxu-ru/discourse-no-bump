# name: discourse-no-bump
# about: Prevents users from bumping their own topics
# version: 0.1
# authors: Robin Ward

enabled_site_setting :no_bump_enabled

after_initialize do

  class ::NoBumpValidator < ActiveModel::Validator
    def validate(record)
      return unless SiteSetting.no_bump_enabled?
      return if record.topic.user_id != record.user_id
      return if record.user.staff? ||
        record.user.trust_level > SiteSetting.no_bump_trust_level

      last_post_user_id = Post
        .with_deleted
        .where(topic_id: record.topic_id)
        .order('post_number desc')
        .limit(1)
        .pluck(:user_id)
        .first

      if last_post_user_id == record.user_id
        record.errors[:base] << "Can't bump that"
      end

    end
  end

  class ::Post < ActiveRecord::Base
    validates_with NoBumpValidator
  end
end
