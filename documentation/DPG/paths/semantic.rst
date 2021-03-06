..
   Athena document is copyright 2016 Bruce Ravel and released under
   The Creative Commons Attribution-ShareAlike License
   http://creativecommons.org/licenses/by-sa/3.0/

Semantic path descriptions
==========================

:demeter:`demeter` does away with the old-fashioned way of organizing
the paths calculated in a :demeter:`feff` calculation.  The
:quoted:`path index` is no longer explicitly used in a
:demeter:`demeter` program. Nonetheless, to build Path objects from a
list of ScatteringPath objects, you need to know something about which
path is which. The `path interpretation <../feff/intrp.tt>`__ is one
good way of obtaining information about the list of paths, but it is
not especially useful for finding automated solutions to building
fitting models.

Consider a situation where a molecule is adsorbed to a surface. As an
example, consider a ruthenium complex on an aluminum oxide support. One
might run a series of DFT or molecular dynamics calculations in an
attempt to determine the position at the surface where the molecule
rests. Presumably the scattering from the atoms in the surface will be
used to identify the surface position by analysis of the EXAFS data.
Given several candidate positions, one would automate the construction
of a simple fitting model which includes scattering from surface atoms.

The difficulty of this approach is that the single scattering paths from
atoms in the surface might be in different positions in :demeter:`feff`'s path list
depending on details of the structural geometry. If you want to include
a single scattering path from, to use the example with the aluminum
oxide support, an aluminum atom in the surface. Doing so is difficult to
automate as you may not know :demeter:`feff`'s path index for that path going into
the fit.

:demeter:`demeter` offers a solution to this problem. You can specify a path using
a semnatic description of the path. For example, you can find the single
scattering path which scatters from aluminum and is between 3 and 4 |AA|
from the scatterer. The following snippet of code imports a :demeter:`feff`
calculation from its serialization file and finds the path meeting that
description:

.. code-block:: perl

      my $feff = Demeter::Feff->new(yaml=>'myfeff.yaml', workspace=>'mycalc');
      my $this_sp = $feff->find_path(gt => 3, lt=>4, tag=>['Al']);
      my $path = Demeter::Path -> new(feff => $feff,
                                      sp   => $this_sp,
                                     ); 

The ``find_path`` method examines all the paths in a Feff objects path
list and compares them against the semantic descriptions given as
arguments to the method. In this case, the path that gets returned
must have a half path length greater than 3 |AA| and less that 4
|AA|. As the anonymous list given as the tag argument has only one
element, the path that returns must be a single scattering path. The
scatterer must have a site tag that equals the string :quoted:`Al`.

If there are more than one path meeting the criteria outlined in the
argument, then the ``find_path`` method returns the shortest such
path.  The ``find_all_paths`` takes the same sort of argument list as
``find_path`` and will return a list of paths meeting the criteria and
ordered by increasing half path length.

Here are all the criteria available to the ``find_path`` and
``find_all_paths`` methods:

``lt``
    This criterion takes a number and requires that the returned path be
    shorter in half path length than that number.
``gt``
    This criterion takes a number and requires that the returned path be
    longer in half path length than that number.
``nleg``
    This criterion takes an integer and requires that the returned path
    have this number of scattering legs. This criterion is redundant
    when the list-valued criteria are also used.
``sp``
    This criterion takes a ScatteringPath object and requires that the
    returned path be longer in half path length than that path.
``tag``
    This criterion takes a string or an anonymous array of strings and
    requires that the returned path contain the atoms which have this
    (these) tags. The tag is the optional fifth column in a :file:`feff.inp`
    file written by Demeter's Atoms. This criterion requires that the
    tags are lexically equal. See the tagmatch criterion for matching
    tags in the sense of regular expressions.
``tagmatch``
    This criterion takes a string or an anonymous array of strings and
    requires that the returned path contain the atoms which have tags
    matching the arguments of this criterion. The tag is the optional
    fifth column in a :file:`feff.inp` file written by Demeter's Atoms. This
    criterion requires that the tags match in the sense of regular
    expressions. See the tag criterion for requiring that tags be
    lexically equal.
``ipot``
    This criterion takes an integer from 0 to 7 or an anonymous array of
    such integers and requires that the returned path contain the atoms
    which have ipots equal to the arguments of this criterion.
``element``
    This criterion takes a string identifying an element (its name, its
    one or two letter symbol or its Z number) or an anonymous array of
    such strings and requires that the returned path contain the atoms
    which have the elements specified.

This method returns 0 if a path meeting the criteria cannot be found or
if there is an error in specifying the criteria.

The list-valued criterion are compared in order with the scattering
atoms in a path and the match is only true if each element hits with
the corresponding scatterer in a path.  Thus, it is not necessary to
specify the nleg criterion when any of the list valued criteria are
used.

Here is an example of using the ``find_all_paths`` method to find all
single scattering paths in a :demeter:`feff` calculcation which are
shorter than 6 |AA|.

.. code-block:: perl

  my @list = $feff->find_all_paths( lt=>6, nleg=>2 );

For more details, see the Demeter::Feff::Paths documentation.

The `example of Hg absorbed to DNA <../examples/hgdna.tt>`__
demonstrates extensive use of the ``find_path`` method. The `silver/gold
alloy example <../examples/agau.tt>`__ also makes strategic use of this
tool.

