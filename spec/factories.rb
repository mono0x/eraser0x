# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :ramuramu_message, :class => Eraser::Message do
    text '(＃＾ω＾)ﾗﾑﾗﾑ'
  end

  factory :pikipiki_message, :class => Eraser::Message do
    text '(＃＾ω＾)ﾋﾟｷﾋﾟｷ'
  end
end
