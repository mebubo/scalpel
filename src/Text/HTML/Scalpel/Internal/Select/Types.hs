{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE ImpredicativeTypes #-}
{-# OPTIONS_HADDOCK hide #-}
module Text.HTML.Scalpel.Internal.Select.Types (
    Selector (..)
,   AttributePredicate (..)
,   checkPred
,   Any (..)
,   AttributeName (..)
,   TagName (..)
,   SelectNode (..)
,   tagSelector
,   anySelector
,   toSelectNode
) where

import Data.Char (toLower)
import Data.String (IsString, fromString)

import qualified Text.HTML.TagSoup as TagSoup
import qualified Text.StringLike as TagSoup
import qualified Data.Text as T


-- | The 'AttributeName' class defines a class of types that can be used when
-- creating 'Selector's to specify the name of an attribute of a tag.  Currently
-- the only types of this class are 'String' for matching attributes exactly,
-- and 'Any' for matching attributes with any name.
class AttributeName k where
    matchKey :: TagSoup.StringLike str => k -> str -> Bool

-- | An 'AttributePredicate' is a method that takes a 'TagSoup.Attribute' and
-- returns a 'Bool' indicating if the given attribute matches a predicate.
data AttributePredicate
        = MkAttributePredicate
                (forall str. TagSoup.StringLike str => TagSoup.Attribute str
                                                    -> Bool)

checkPred :: TagSoup.StringLike str
          => AttributePredicate -> TagSoup.Attribute str -> Bool
checkPred (MkAttributePredicate p) = p

-- | 'Any' can be used as a wildcard when constructing selectors to match tags
-- and attributes with any name.
--
-- For example, the selector @Any \@: [Any \@= \"foo\"]@ matches all tags that
-- have any attribute where the value is @\"foo\"@.
data Any = Any

-- | 'Selector' defines a selection of an HTML DOM tree to be operated on by
-- a web scraper. The selection includes the opening tag that matches the
-- selection, all of the inner tags, and the corresponding closing tag.
newtype Selector = MkSelector [SelectNode]

tagSelector :: String -> Selector
tagSelector tag = MkSelector [toSelectNode (TagString tag) []]

-- | Substitute for 'Any'.
anySelector :: Selector
anySelector = MkSelector [SelectAny []]

instance IsString Selector where
  fromString = tagSelector

data SelectNode = SelectNode !T.Text [AttributePredicate]
                | SelectAny [AttributePredicate]

-- instance Selectable Selector where
--     toSelector = id
--
-- instance Selectable String where
--     toSelector node = MkSelector [SelectNode (T.pack $ map toLower node) []]
--
-- instance Selectable Any where
--     toSelector = const (MkSelector [SelectAny []])

instance AttributeName Any where
    matchKey = const . const True

instance AttributeName String where
    matchKey = (==) . TagSoup.fromString . map toLower

-- | The 'TagName' type is used when creating a 'Selector' to specify the name
-- of a tag.
data TagName = AnyTag | TagString String

instance IsString TagName where
    fromString = TagString

toSelectNode :: TagName -> [AttributePredicate] -> SelectNode
toSelectNode AnyTag = SelectAny
toSelectNode (TagString str) = SelectNode . TagSoup.fromString $ map toLower str
