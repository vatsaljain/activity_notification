shared_examples_for :renderable do
  let(:test_class_name) { described_class.to_s.underscore.split('/').last.to_sym }
  let(:test_target) { create(:user) }
  let(:test_instance) { create(test_class_name, target: test_target) }
  let(:target_type_key) { 'user' }

  let(:notifier_name)        { 'foo' }
  let(:article_title)        { 'bar' }
  let(:group_member_count)   { 3 }
  let(:simple_text_key)      { 'article.create' }
  let(:params_text_key)      { 'comment.post' }
  let(:group_text_key)       { 'comment.reply' }
  let(:simple_text_original) { 'Article has been created' }
  let(:params_text_original) { "<p>%{notifier_name} posted comments to your article %{article_title}</p>" }
  let(:group_text_original)  { "<p>%{notifier_name} and %{group_member_count} people replied for your comments</p>" }
  let(:params_text_embedded) { "<p>foo posted comments to your article bar</p>" }
  let(:group_text_embedded)  { "<p>foo and 3 people replied for your comments</p>" }

  describe "i18n configuration" do
    it "has key configured for simple text" do
      expect(I18n.t("notification.#{target_type_key}.#{simple_text_key}.text"))
        .to eq(simple_text_original)
    end

    it "has key configured with embedded params" do
      expect(I18n.t("notification.#{target_type_key}.#{params_text_key}.text"))
        .to eq(params_text_original)
      expect(I18n.t("notification.#{target_type_key}.#{params_text_key}.text",
        {notifier_name: notifier_name, article_title: article_title}))
        .to eq(params_text_embedded)
    end

    it "has key configured with embedded params including group_member_count" do
      expect(I18n.t("notification.#{target_type_key}.#{group_text_key}.text"))
        .to eq(group_text_original)
      expect(I18n.t("notification.#{target_type_key}.#{group_text_key}.text",
        {notifier_name: notifier_name, group_member_count: group_member_count}))
        .to eq(group_text_embedded)
    end
  end

  describe "as public instance methods" do
    describe "#text" do
      context "without params argument" do
        context "with target type of test instance" do
          it "uses text from key" do
            test_instance.key = simple_text_key
            expect(test_instance.text).to eq(simple_text_original)
          end

          it "uses text from key with notification namespace" do
            test_instance.key = "notification.#{simple_text_key}"
            expect(test_instance.text).to eq(simple_text_original)
          end

          context "when the text is missing for the target type" do
            it "returns translation missing text" do
              test_instance.target = create(:admin)
              test_instance.key = "notification.#{simple_text_key}"
              expect(test_instance.text)
                .to eq("translation missing: en.notification.admin.#{simple_text_key}.text")
            end
          end

          context "when the text has embedded parameters" do
            it "raises MissingInterpolationArgument without embedded parameters" do
              test_instance.key = params_text_key
              expect { test_instance.text }
                .to raise_error(I18n::MissingInterpolationArgument)
            end
          end
        end
      end

      context "with params argument" do
        context "with target type of target parameter" do
          it "uses text from key" do
            test_instance.target = create(:admin)
            test_instance.key = simple_text_key
            expect(test_instance.text({target: :user})).to eq(simple_text_original)
          end

          context "when the text has embedded parameters" do
            it "uses text with embedded parameters" do
              test_instance.key = params_text_key
              expect(test_instance.text({notifier_name: notifier_name, article_title: article_title}))
                .to eq(params_text_embedded)
            end

            it "uses text with automatically embedded group_member_count" do
              # Create 3 group members
              create(test_class_name, target: test_instance.target, group_owner: test_instance)
              create(test_class_name, target: test_instance.target, group_owner: test_instance)
              create(test_class_name, target: test_instance.target, group_owner: test_instance)
              test_instance.key = group_text_key
              expect(test_instance.text({notifier_name: notifier_name}))
                .to eq(group_text_embedded)
            end
          end
        end
      end
    end

    # Test with view_helper for the following methods
    # #render
    # #partial_path
    # #layout_path

  end
end