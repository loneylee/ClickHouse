#include <Columns/ColumnConst.h>
#include <Columns/ColumnString.h>
#include <DataTypes/DataTypesDecimal.h>
#include <Functions/FunctionFactory.h>
#include <Functions/FunctionHelpers.h>
#include <Functions/IFunction.h>
#include <Common/intExp.h>


namespace DB
{
namespace ErrorCodes
{
    extern const int NUMBER_OF_ARGUMENTS_DOESNT_MATCH;
    extern const int ILLEGAL_TYPE_OF_ARGUMENT;
    extern const int ILLEGAL_COLUMN;
}

struct NameUnscaleValue
{
    static constexpr auto name = "unscaleValue";
};

template <typename T>
    requires(is_decimal<T>)
static DataTypePtr createNativeDataType()
{
    return std::make_shared<DataTypeNumber<typename T::NativeType>>();
}

namespace
{
    template <typename Name>
    class FunctionUnscaleValue : public IFunction
    {
    public:
        static constexpr auto name = Name::name;

        static FunctionPtr create(ContextPtr) { return std::make_shared<FunctionUnscaleValue>(); }

        String getName() const override { return name; }
        bool isVariadic() const override { return true; }
        size_t getNumberOfArguments() const override { return 3; }
        bool isSuitableForShortCircuitArgumentsExecution(const DataTypesWithConstInfo & /*arguments*/) const override { return false; }

        DataTypePtr getReturnTypeImpl(const ColumnsWithTypeAndName & arguments) const override
        {
            if (arguments.empty() || arguments.size() != 1)
                throw Exception(
                    ErrorCodes::NUMBER_OF_ARGUMENTS_DOESNT_MATCH,
                    "Number of arguments for function {} doesn't match: passed {}, should be 1.",
                    getName(),
                    arguments.size());


            if (!isDecimal(arguments[0].type))
                throw Exception(
                    ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT,
                    "Illegal type {} of argument of function {}, expected Decimal",
                    arguments[0].type->getName(),
                    getName());

            WhichDataType which(arguments[0].type);

            if (which.isDecimal32())
                return createNativeDataType<Decimal32>();
            else if (which.isDecimal64())
                return createNativeDataType<Decimal64>();
            else if (which.isDecimal128())
                return createNativeDataType<Decimal128>();
            else
                return createNativeDataType<Decimal256>();
        }

        ColumnPtr
        executeImpl(const ColumnsWithTypeAndName & arguments, const DataTypePtr & result_type, size_t input_rows_count) const override
        {
            const auto & unscale_column = arguments[0];
            if (!unscale_column.column)
                throw Exception(ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT, "Illegal column while execute function {}", getName());

            auto col_to = result_type->createColumn();
            col_to->reserve(input_rows_count);

            if (const auto * decimal32 = checkAndGetColumn<ColumnDecimal<Decimal32>>(*unscale_column.column))
            {
                unscaleValue<Decimal32::NativeType>(*decimal32, col_to, input_rows_count);
            }
            else if (const auto * decimal64 = checkAndGetColumn<ColumnDecimal<Decimal64>>(*unscale_column.column))
            {
                unscaleValue<Decimal64::NativeType>(*decimal64, col_to, input_rows_count);
            }
            else if (const auto * decimal128 = checkAndGetColumn<ColumnDecimal<Decimal128>>(*unscale_column.column))
            {
                unscaleValue<Decimal128::NativeType>(*decimal128, col_to, input_rows_count);
            }
            else if (const auto * decimal256 = checkAndGetColumn<ColumnDecimal<Decimal256>>(*unscale_column.column))
            {
                unscaleValue<Decimal256::NativeType>(*decimal256, col_to, input_rows_count);
            }
            else
                col_to->insertDefault();

            return col_to;
        }

    private:
        template <typename T>
        static void unscaleValue(const ColumnDecimal<Decimal<T>> & columns, MutableColumnPtr & col_to, size_t input_rows_count)
        {
            for (size_t i = 0; i < input_rows_count; ++i)
            {
                col_to->insert(columns.getElement(i).value);
            }
        }
    };

}

REGISTER_FUNCTION(UnscaleValue)
{
    factory.registerFunction<FunctionUnscaleValue<NameUnscaleValue>>();
}
}
