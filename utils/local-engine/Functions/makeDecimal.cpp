#include <Columns/ColumnConst.h>
#include <Columns/ColumnDecimal.h>
#include <Columns/ColumnsNumber.h>
#include <DataTypes/DataTypesDecimal.h>
#include <DataTypes/DataTypesNumber.h>
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

}

namespace local_engine
{
using namespace DB;

struct NameMakeDecimal32
{
    static constexpr auto name = "makeDecimal32";
};
struct NameMakeDecimal64
{
    static constexpr auto name = "makeDecimal64";
};
struct NameMakeDecimal128
{
    static constexpr auto name = "makeDecimal128";
};
struct NameMakeDecimal256
{
    static constexpr auto name = "makeDecimal256";
};
struct NameMakeDecimal32OrNull
{
    static constexpr auto name = "makeDecimal32OrNull";
};
struct NameMakeDecimal64OrNull
{
    static constexpr auto name = "makeDecimal64OrNull";
};
struct NameMakeDecimal128OrNull
{
    static constexpr auto name = "makeDecimal128OrNull";
};
struct NameMakeDecimal256OrNull
{
    static constexpr auto name = "makeDecimal256OrNull";
};


enum class ConvertExceptionMode
{
    Throw, /// Throw exception if value cannot be parsed.
    Null /// Return ColumnNullable with NULLs when value cannot be parsed.
};

inline UInt32 extractArgument(const ColumnWithTypeAndName & named_column)
{
    Field field;
    named_column.column->get(0, field);
    return static_cast<UInt32>(field.get<UInt32>());
}
namespace
{
    template <typename ToDataType, typename Name, ConvertExceptionMode exception_mode>
    class FunctionMakeDecimal : public IFunction
    {
    public:
        static constexpr auto name = Name::name;

        //    static FunctionPtr create(ContextPtr)
        //    {
        //        return std::make_shared<FunctionMakeDecimal>();
        //    }

        String getName() const override { return name; }
        bool isVariadic() const override { return true; }
        size_t getNumberOfArguments() const override { return 3; }
        //    bool isSuitableForShortCircuitArgumentsExecution(const DataTypesWithConstInfo & /*arguments*/) const override { return false; }

        DataTypePtr getReturnTypeImpl(const ColumnsWithTypeAndName & arguments) const override
        {
            if (arguments.empty() || arguments.size() != 3)
                throw Exception(
                    ErrorCodes::NUMBER_OF_ARGUMENTS_DOESNT_MATCH,
                    "Number of arguments for function {} doesn't match: passed {}, should be 3.",
                    getName(),
                    arguments.size());

            if (!isInteger(arguments[0].type) || !isInteger(arguments[1].type) || !isInteger(arguments[2].type))
                throw Exception(
                    ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT,
                    "Cannot format {} {} {} as decimal",
                    arguments[0].type->getName(),
                    arguments[1].type->getName(),
                    arguments[2].type->getName());

            DataTypePtr res = createDecimal<DataTypeDecimal>(extractArgument(arguments[1]), extractArgument(arguments[2]));

            if constexpr (exception_mode == ConvertExceptionMode::Null)
                return std::make_shared<DataTypeNullable>(res);

            return res;
        }

        ColumnPtr executeImpl(const ColumnsWithTypeAndName & arguments, const DataTypePtr & result_type, size_t input_rows_count) const override
        {
            auto & unscale_column = arguments[0];
            if (!unscale_column.column)
                throw Exception(ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT, "Illegal column while execute function {}", getName());

            auto & precision_column = arguments[1];
            auto & scale_column = arguments[2];

            DataTypePtr  dt  = createDecimal<DataTypeDecimal>(extractArgument(precision_column), extractArgument(scale_column));

            if ()



            auto dec = checkAndGetDataType<DataTypeDecimal<Decimal32>>(result_type.get());


            static_cast<DataTypeDecimal<Decimal32>>(converted_value);


            UInt32 precision = 0;
            if (arguments.size() == 2)
            {
                const auto & precision_column = arguments[1];
                if (!precision_column.column)
                    throw Exception(ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT, "Illegal column while execute function {}", getName());

                const ColumnConst * const_column = checkAndGetColumnConst<ColumnUInt8>(precision_column.column.get());
                if (!const_column)
                    throw Exception(
                        ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT,
                        "Second argument for function {} must be constant UInt8: "
                        "precision.",
                        getName());

                precision = const_column->getValue<UInt8>();
            }
            else
                precision = getDecimalPrecision(*src_column.type);

            auto result_column = ColumnUInt8::create();

            auto call = [&](const auto & types) -> bool //-V657
            {
                using Types = std::decay_t<decltype(types)>;
                using Type = typename Types::RightType;
                using ColVecType = ColumnDecimal<Type>;

                if (const ColumnConst * const_column = checkAndGetColumnConst<ColVecType>(src_column.column.get()))
                {
                    Type const_decimal = checkAndGetColumn<ColVecType>(const_column->getDataColumnPtr().get())->getData()[0];
                    UInt8 res_value = outOfDigits<Type>(const_decimal, precision);
                    result_column->getData().resize_fill(input_rows_count, res_value);
                    return true;
                }
                else if (const ColVecType * col_vec = checkAndGetColumn<ColVecType>(src_column.column.get()))
                {
                    execute<Type>(*col_vec, *result_column, input_rows_count, precision);
                    return true;
                }

                throw Exception(ErrorCodes::ILLEGAL_TYPE_OF_ARGUMENT, "Illegal column while execute function {}", getName());
            };

            TypeIndex dec_type_idx = src_column.type->getTypeId();
            if (!callOnBasicType<void, false, false, true, false>(dec_type_idx, call))
                throw Exception(ErrorCodes::ILLEGAL_COLUMN, "Wrong call for {} with {}", getName(), src_column.type->getName());

            return result_column;
        }


    private:
        template <typename T>
        static void execute(const ColumnDecimal<T> & col, ColumnUInt8 & result_column, size_t rows_count, UInt32 precision)
        {
            const auto & src_data = col.getData();
            auto & dst_data = result_column.getData();
            dst_data.resize(rows_count);

            for (size_t i = 0; i < rows_count; ++i)
                dst_data[i] = outOfDigits<T>(src_data[i], precision);
        }

        template <is_decimal T>
        static bool outOfDigits(T dec, UInt32 precision)
        {
            using NativeT = typename T::NativeType;

            if (precision > DecimalUtils::max_precision<T>)
                return false;

            NativeT pow10 = intExp10OfSize<NativeT>(precision);

            if (dec.value < 0)
                return dec.value <= -pow10;
            return dec.value >= pow10;
        }
    };

    using FunctionToDecimal32 = FunctionMakeDecimal<DataTypeDecimal<Decimal32>, NameMakeDecimal32, ConvertExceptionMode::Throw>;
    using FunctionToDecimal64 = FunctionMakeDecimal<DataTypeDecimal<Decimal64>, NameMakeDecimal64, ConvertExceptionMode::Throw>;
    using FunctionToDecimal128 = FunctionMakeDecimal<DataTypeDecimal<Decimal128>, NameMakeDecimal128, ConvertExceptionMode::Throw>;
    using FunctionToDecimal256 = FunctionMakeDecimal<DataTypeDecimal<Decimal256>, NameMakeDecimal256, ConvertExceptionMode::Throw>;
    using FunctionToDecimal32OrNull = FunctionMakeDecimal<DataTypeDecimal<Decimal32>, NameMakeDecimal32, ConvertExceptionMode::Null>;
    using FunctionToDecimal64OrNull = FunctionMakeDecimal<DataTypeDecimal<Decimal64>, NameMakeDecimal64, ConvertExceptionMode::Null>;
    using FunctionToDecimal128OrNull = FunctionMakeDecimal<DataTypeDecimal<Decimal128>, NameMakeDecimal128, ConvertExceptionMode::Null>;
    using FunctionToDecimal256OrNull = FunctionMakeDecimal<DataTypeDecimal<Decimal256>, NameMakeDecimal256, ConvertExceptionMode::Null>;

}

void registerFunctionMakeDecimal(FunctionFactory & factory)
{
    factory.registerFunction<FunctionToDecimal32>();
    factory.registerFunction<FunctionToDecimal64>();
    factory.registerFunction<FunctionToDecimal128>();
    factory.registerFunction<FunctionToDecimal256>();
    factory.registerFunction<FunctionToDecimal32OrNull>();
    factory.registerFunction<FunctionToDecimal64OrNull>();
    factory.registerFunction<FunctionToDecimal128OrNull>();
    factory.registerFunction<FunctionToDecimal256OrNull>();
}

}
