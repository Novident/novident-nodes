# 🗃️ Novident Nodes

> [!WARNING]
> This is a library just for internal uses of Novident application 
> and the packages related with the app. 
>
> This package can change constantly and may even have drastic breaking changes.
>
> Please, ensure that you're not using this package, since the values 
> into it wont work for other packages than Novident packages.

The nodes within this package have a specific behavior, and they are capable of updating themselves internally without having to do so themselves.

> [!NOTE]
> This doesn't mean we have to perform certain validations, as some errors could occur.

In the case of Novident, these packages have multiple uses in different packages:

- **[Novident-corkboard](https://github.com/Novident/novident-corkboard):** Nodes are used to display nodes in different ways in a customized way, such as creating index cards that can have a defined shape or a defined point on the screen, or even having what we call freeform node mode, which allows us to move these cards to any position we want.

- **[Novident-tree-view](https://github.com/Novident/novident-tree-view):** Nodes are used to define where and how nodes will be displayed in a widget tree. It's quite similar to **TreeSliverView**, but this implementation is more tailored to work with Novident standards.

For now, these will be the most common uses. In the long term, the definition of these nodes may change, depending on Novident's needs and the feature being built.

