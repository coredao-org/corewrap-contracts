// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../erc20/interfaces/IERC20.sol";
import "../../libraries/ScriptTypesEnum.sol";
import "../types/DataTypes.sol";

library LockersLib {

    function maximumBuyableCollateral(
        DataTypes.locker memory theLocker,
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _priceOfOneUnitOfCollateral
    ) external view returns (uint) {

        // maxBuyable <= (upperHealthFactor*netMinted*liquidationRatio/10000 - nativeTokenLockedAmount*nativeTokenPrice)/(upperHealthFactor*liquidationRatio*discountedPrice - nativeTokenPrice)
        //  => maxBuyable <= (upperHealthFactor*netMinted*liquidationRatio * 10^18  - nativeTokenLockedAmount*nativeTokenPrice * 10^8)/(upperHealthFactor*liquidationRatio*discountedPrice - nativeTokenPrice * 10^8)

        uint teleBTCDecimal = IERC20(libParams.teleBTC).decimals();

        uint antecedent = (libConstants.UpperHealthFactor * theLocker.netMinted * libParams.liquidationRatio * (10 ** libConstants.NativeTokenDecimal)) -
        (theLocker.nativeTokenLockedAmount * _priceOfOneUnitOfCollateral * (10 ** teleBTCDecimal));

        uint consequent = ((libConstants.UpperHealthFactor * libParams.liquidationRatio * _priceOfOneUnitOfCollateral * libParams.priceWithDiscountRatio)/libConstants.OneHundredPercent) -
        (_priceOfOneUnitOfCollateral * (10 ** teleBTCDecimal));

        return antecedent/consequent;
    }

    function calculateHealthFactor(
        DataTypes.locker memory theLocker,
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _priceOfOneUnitOfCollateral
    ) external view returns (uint) {
        return (_priceOfOneUnitOfCollateral * theLocker.nativeTokenLockedAmount * (10 ** (1 + IERC20(libParams.teleBTC).decimals())))/
        (theLocker.netMinted * libParams.liquidationRatio * (10 ** (1 + libConstants.NativeTokenDecimal)));
    }

    function neededTeleBTCToBuyCollateral(
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _collateralAmount,
        uint _priceOfCollateral
    ) external pure returns (uint) {
        return (_collateralAmount * _priceOfCollateral * libParams.priceWithDiscountRatio)/
        (libConstants.OneHundredPercent*(10 ** libConstants.NativeTokenDecimal));
    }

    function addToCollateral(
        DataTypes.locker storage theLocker,
        uint _addingNativeTokenAmount
    ) external {

        require(
            theLocker.isLocker,
            "Lockers: account is not a locker"
        );

        theLocker.nativeTokenLockedAmount =
        theLocker.nativeTokenLockedAmount + _addingNativeTokenAmount;
    }

    function removeFromCollateral(
        DataTypes.locker storage theLocker,
        DataTypes.lockersLibConstants memory libConstants,
        DataTypes.lockersLibParam memory libParams,
        uint _priceOfOneUnitOfCollateral,
        uint _removingNativeTokenAmount
    ) internal {

        require(
            theLocker.isLocker,
            "Lockers: account is not a locker"
        );

        // lockerCapacity = valueOfNativeTokenLockedAmountInBTC - netMinted

        uint lockerCapacity = (theLocker.nativeTokenLockedAmount * _priceOfOneUnitOfCollateral * libConstants.OneHundredPercent)/
        (libParams.collateralRatio * (10 ** libConstants.NativeTokenDecimal)) - theLocker.netMinted;

        uint maxRemovableCollateral = (lockerCapacity * (10 ** libConstants.NativeTokenDecimal))/_priceOfOneUnitOfCollateral;

        require(
            _removingNativeTokenAmount <= maxRemovableCollateral,
            "Lockers: more than max removable collateral"
        );

        theLocker.nativeTokenLockedAmount =
        theLocker.nativeTokenLockedAmount - _removingNativeTokenAmount;
    }

}




