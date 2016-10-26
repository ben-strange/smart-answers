require_relative "../../test_helper"

module SmartAnswer
  module Calculators
    class StudentFinanceCalculatorTest < ActiveSupport::TestCase
      test "StudentFinanceCalculator is valid and setup properly" do
        calculator = StudentFinanceCalculator.new(
          course_start: '2016-2017',
          household_income: 15_000,
          residence: 'at-home',
          course_type: 'uk-full-time'
        )
        assert_instance_of StudentFinanceCalculator, calculator

        assert_equal '2016-2017', calculator.course_start
        assert_equal 15000, calculator.household_income
        assert_equal 'at-home', calculator.residence
        assert_equal 'uk-full-time', calculator.course_type
      end

      test "StudentFinanceCalculator instance variables can be changed after initialisation" do
        calculator = StudentFinanceCalculator.new

        assert_instance_of StudentFinanceCalculator, calculator

        assert_equal nil, calculator.course_start
        assert_equal nil, calculator.household_income
        assert_equal nil, calculator.residence
        assert_equal nil, calculator.course_type

        calculator.course_start = '2016-2017'
        calculator.household_income = 15_000
        calculator.residence = 'at-home'
        calculator.course_type = 'uk-full-time'

        assert_equal '2016-2017', calculator.course_start
        assert_equal 15000, calculator.household_income
        assert_equal 'at-home', calculator.residence
        assert_equal 'uk-full-time', calculator.course_type
      end

      context "childcare_grant" do
        context "for one child" do
          context "in 2016-2017" do
            should "be 155.24" do
              calculator = StudentFinanceCalculator.new(
                course_start: "2016-2017",
                household_income: 25_000,
                residence: :unused_variable
              )
              assert_equal 155.24, calculator.childcare_grant_one_child
            end
          end
        end
        context "for more than one child" do
          context "in 2016-2017" do
            should "be 266.15" do
              calculator = StudentFinanceCalculator.new(
                course_start: "2016-2017",
                household_income: 25_000,
                residence: :unused_variable
              )
              assert_equal 266.15, calculator.childcare_grant_more_than_one_child
            end
          end
        end
      end

      context "#parent_learning_allowance" do
        should "be 1573 in 2016-2017" do
          calculator = StudentFinanceCalculator.new(
            course_start: "2016-2017",
            household_income: 25_000,
            residence: :unused_variable
          )
          assert_equal 1573, calculator.parent_learning_allowance
        end
      end

      context "#adult_dependant_allowance" do
        should "be 2757 in 2016-2017" do
          calculator = StudentFinanceCalculator.new(
            course_start: "2016-2017",
            household_income: 25_000,
            residence: :unused_variable
          )
          assert_equal 2757, calculator.adult_dependant_allowance
        end
      end

      context "maximum tuition fee" do
        context "for a full time student" do
          context "in 2016-2017" do
            should "be 9000" do
              calculator = StudentFinanceCalculator.new(
                course_start: "2016-2017",
                household_income: 25_000,
                residence: :unused_variable
              )
              assert_equal 9000, calculator.tuition_fee_maximum_full_time
            end
          end
        end
        context "for part time student" do
          context "in 2016-2017" do
            should "be 6750" do
              calculator = StudentFinanceCalculator.new(
                course_start: "2016-2017",
                household_income: 25_000,
                residence: :unused_variable
              )
              assert_equal 6750, calculator.tuition_fee_maximum_part_time
            end
          end
        end
      end

      context "#maintenance_grant_amount" do
        context "for students who started 2016-2017 or later" do
          setup do
            @course_start = '2016-2017'
          end
          should "return 0 for any student" do
            calculator = StudentFinanceCalculator.new(
              course_start: @course_start,
              household_income: 15_000,
              residence: :unused_variable
            )
            assert_equal Money.new(0).to_s, calculator.maintenance_grant_amount.to_s
          end
        end
      end

      context "#maintenance_loan_amount" do
        context "for students who started 2016-2017 living at home with parents" do
          setup do
            @course_start = '2016-2017'
            @residence = 'at-home'
          end

          should "give the maximum amount of £6,904 if household income is £25k or below" do
            calculator = StudentFinanceCalculator.new(
              course_start: @course_start,
              household_income: 25_000,
              residence: @residence
            )
            assert_equal Money.new(6_904).to_s, calculator.maintenance_loan_amount.to_s
          end

          should "reduce the maximum amount (£6,904) by £1 for every complete £8.59 of income above £25k" do
            # Samples taken from the document provided
            {
              30_000 => 6_322,
              35_000 => 5_740,
              40_000 => 5_158,
              42_875 => 4_824,
              45_000 => 4_576,
              50_000 => 3_994,
              55_000 => 3_412,
              58_201 => 3_039
            }.each do |household_income, loan_amount|
              calculator = StudentFinanceCalculator.new(
                course_start: @course_start,
                household_income: household_income,
                residence: @residence
              )
              assert_equal Money.new(loan_amount).to_s, calculator.maintenance_loan_amount.to_s
            end
          end

          should "cap the reductions and give the minimum loan of £3,039 for high household income students" do
            calculator = StudentFinanceCalculator.new(
              course_start: @course_start,
              household_income: 500_000,
              residence: @residence
            )
            assert_equal Money.new(3_039).to_s, calculator.maintenance_loan_amount.to_s
          end
        end

        context "for students who started 2016-2017 living away not in london" do
          setup do
            @course_start = '2016-2017'
            @residence = 'away-outside-london'
          end

          should "give the maximum amount of £8,200 if household income is £25k or below" do
            calculator = StudentFinanceCalculator.new(
              course_start: @course_start,
              household_income: 25_000,
              residence: @residence
            )
            assert_equal Money.new(8_200).to_s, calculator.maintenance_loan_amount.to_s
          end

          should "reduce the maximum amount (£8,200) by £1 for every complete £8.49 of income above £25k" do
            # Samples taken from the document provided
            {
              30_000 => 7_612,
              35_000 => 7_023,
              40_000 => 6_434,
              42_875 => 6_095,
              45_000 => 5_845,
              50_000 => 5_256,
              55_000 => 4_667,
              60_000 => 4_078,
              62_180 => 3_821
            }.each do |household_income, loan_amount|
              calculator = StudentFinanceCalculator.new(
                course_start: @course_start,
                household_income: household_income,
                residence: @residence
              )
              assert_equal Money.new(loan_amount).to_s, calculator.maintenance_loan_amount.to_s
            end
          end

          should "cap the reductions and give the minimum loan of £3,821 for high household income students" do
            calculator = StudentFinanceCalculator.new(
              course_start: @course_start,
              household_income: 500_000,
              residence: @residence
            )
            assert_equal Money.new(3_821).to_s, calculator.maintenance_loan_amount.to_s
          end
        end

        context "for students who started 2016-2017 living away in london" do
          setup do
            @course_start = '2016-2017'
            @residence = 'away-in-london'
          end

          should "give the maximum amount of £10,702 if household income is £25k or below" do
            calculator = StudentFinanceCalculator.new(
              course_start: @course_start,
              household_income: 25_000,
              residence: @residence
            )
            assert_equal Money.new(10_702).to_s, calculator.maintenance_loan_amount.to_s
          end

          should "reduce the maximum amount (£10,702) by £1 for every complete £8.34 of income above £25k" do
            # Samples taken from the document provided
            {
              30_000 => 10_103,
              35_000 => 9_503,
              40_000 => 8_904,
              42_875 => 8_559,
              45_000 => 8_304,
              50_000 => 7_705,
              55_000 => 7_105,
              60_000 => 6_506,
              65_000 => 5_906,
              69_803 => 5_330
            }.each do |household_income, loan_amount|
              calculator = StudentFinanceCalculator.new(
                course_start: @course_start,
                household_income: household_income,
                residence: @residence
              )
              assert_equal Money.new(loan_amount).to_s, calculator.maintenance_loan_amount.to_s
            end
          end

          should "cap the reductions and give the minimum loan of £5,330 for high household income students" do
            calculator = StudentFinanceCalculator.new(
              course_start: @course_start,
              household_income: 500_000,
              residence: @residence
            )
            assert_equal Money.new(5_330).to_s, calculator.maintenance_loan_amount.to_s
          end
        end

        context "#reduced_maintenance_loan_for_healthcare" do
          should "be £3263 for students living away from home in London" do
            calculator = StudentFinanceCalculator.new(
              course_start: @course_start,
              household_income: @household_income,
              residence: 'away-in-london'
            )

            assert_equal 3263, calculator.reduced_maintenance_loan_for_healthcare
          end

          should "be £2324 for students living away from home outside London" do
            calculator = StudentFinanceCalculator.new(
              course_start: @course_start,
              household_income: @household_income,
              residence: 'away-outside-london'
            )

            assert_equal 2324, calculator.reduced_maintenance_loan_for_healthcare
          end

          should "be £1744 for students living away from home outside London" do
            calculator = StudentFinanceCalculator.new(
              course_start: @course_start,
              household_income: @household_income,
              residence: 'at-home'
            )

            assert_equal 1744, calculator.reduced_maintenance_loan_for_healthcare
          end
        end
      end
    end
  end
end
